data "ignition_config" "minecraft" {
  systemd_units = [
    data.ignition_systemd_unit.minecraft.id,
  ]

  files = [
    data.ignition_file.world_puller.id,
    data.ignition_file.world_pusher.id,
  ]
}

data "ignition_systemd_unit" "minecraft" {
  name    = "minecraft.service"
  enabled = true
  content = data.template_file.minecraft.rendered
}

# data "ignition_systemd_unit" "registrar" {
#   name = "registrar.service"

#   content = <<CONTENT
# [Unit]
# Description=Registrar container

# [Service]
# Type=oneshot
# RemainAfterExit=true
# User=core
# Environment="PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
# ExecStartPre=-/usr/bin/docker rm -f registrar

# ExecStart=/usr/bin/docker run --name registrar \
# --restart=on-failure:10 \
# --env-file=/etc/registrar/registrar.env \
# 362995399210.dkr.ecr.ap-southeast-2.amazonaws.com/cgws/registrar:master

# ExecStop=-/usr/bin/docker stop registrar

# [Install]
# WantedBy=multi-user.target
# CONTENT
# }

data "template_file" "minecraft" {
  template = <<EOF
[Unit]
Description=Minecraft server

[Service]
Type=oneshot
RemainAfterExit=true
User=core
Environment="PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
ExecStartPre=-/usr/bin/docker rm -f minecraft
ExecStartPre="/opt/world-puller.sh ${s3_bucket}/world.tgz /opt/minecraft/world"

ExecStart=/usr/bin/docker run --name minecraft \
--restart=on-failure:10 \
--env VERSION=${minecraft_version}
--env EULA=TRUE
-v /opt/minecraft:/data
${minecraft_image}

ExecStop=-/usr/bin/docker stop minecraft
ExecStopPost="/opt/world-pusher.sh /opt/minecraft/world ${s3_bucket}/world.tgz"

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

  vars {
    minecraft_image   = "${local.images["minecraft"]}"
    minecraft_version = "${local.minecraft_version}"
    s3_bucket         = "${local.s3_bucket}"
  }
}


data "ignition_file" "world_puller" {
  filesystem = "root"
  path       = "/opt/world-puller.sh"
  mode       = "0755"

  content {
    content = <<CONTENT
#!/bin/bash
set -e
set -o pipefail

if [ "$#" -ne "2" ]; then
    echo "Usage: $0 location destination"
    exit 1
fi

# shellcheck disable=SC2034
LOCATION=$1
# shellcheck disable=SC1083,SC1001
LOCATION_ESCAPED=$${1//\//+}
DESTINATION=$2

s3_pull() {
    # shellcheck disable=SC2086,SC2154,SC2016
    /usr/bin/docker run \
        --volume /tmp:/tmp \
        --network=host \
        --env LOCATION=$LOCATION \
        --env LOCATION_ESCAPED=$LOCATION_ESCAPED \
        --entrypoint=/bin/bash \
        ${local.images["awscli"]} \
        -c '
            set -e
            set -o pipefail
            REGION=$(wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone | sed '"'"'s/[a-zA-Z]$//'"'"')
            /usr/bin/aws --region="$REGION" s3 cp s3://"$LOCATION" /tmp/"$LOCATION_ESCAPED"
        '
}

until s3_pull; do
    echo "failed to pull from S3; retrying in 5 seconds"
    sleep 5
done

/usr/bin/tar -xvzC "$DESTINATION" -f /tmp/"$LOCATION_ESCAPED" 
CONTENT
  }
}


data "ignition_file" "world_pusher" {
  filesystem = "root"
  path       = "/opt/world-pusher.sh"
  mode       = "0755"

  content {
    content = <<CONTENT
#!/bin/bash
set -e
set -o pipefail

if [ "$#" -ne "2" ]; then
    echo "Usage: $0 location destination"
    exit 1
fi

# shellcheck disable=SC2034
LOCATION=$1
# shellcheck disable=SC1083,SC1001
LOCATION_ESCAPED=$${1//\//+}
DESTINATION=$2

/usr/bin/tar -cvzf /tmp/"$LOCATION_ESCAPED" "$DESTINATION"

s3_push() {
    # shellcheck disable=SC2086,SC2154,SC2016
    /usr/bin/docker run \
        --volume /tmp:/tmp \
        --network=host \
        --env LOCATION=$LOCATION \
        --env LOCATION_ESCAPED=$LOCATION_ESCAPED \
        --entrypoint=/bin/bash \
        ${local.images["awscli"]} \
        -c '
            set -e
            set -o pipefail
            REGION=$(wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone | sed '"'"'s/[a-zA-Z]$//'"'"')
            /usr/bin/aws --region="$REGION" s3 cp /tmp/"$LOCATION_ESCAPED" s3://"$DESTINATION"
        '
}

until s3_push; do
    echo "failed to push to S3; retrying in 5 seconds"
    sleep 5
done
CONTENT
  }
}

