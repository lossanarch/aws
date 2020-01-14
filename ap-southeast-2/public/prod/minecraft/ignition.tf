
data "ignition_config" "minecraft" {
  systemd = [
    "${data.ignition_systemd_unit.minecraft.id}",
    "${data.ignition_systemd_unit.registrar.id}",
    "${data.ignition_systemd_unit.update_engine.id}",
    "${data.ignition_systemd_unit.locksmithd.id}",
  ]

  files = [
    "${data.ignition_file.world_puller.id}",
    "${data.ignition_file.world_pusher.id}",
  ]
}


data "ignition_systemd_unit" "update_engine" {
  name = "update-engine.service"
  mask = true
}

data "ignition_systemd_unit" "locksmithd" {
  name = "locksmithd.service"
  mask = true
}

data "ignition_systemd_unit" "minecraft" {
  name = "minecraft.service"

  content = <<EOF
[Unit]
Description=Minecraft server
After=containerd.service docker.socket network-online.target docker.service
Wants=network-online.target
Requires=containerd.service docker.socket docker.service

[Service]
Type=exec
RemainAfterExit=true
Environment="PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
ExecStartPre=-/usr/bin/docker rm -f minecraft
ExecStartPre=-/usr/bin/mkdir -p /opt/minecraft/world
ExecStartPre=/opt/world-puller.sh ${var.s3_bucket}/world.tgz /opt/minecraft/world

ExecStart=/usr/bin/docker run --name minecraft \
--restart=on-failure:10 \
--env VERSION=${var.minecraft_version} \
--env EULA=TRUE \
--env DIFFICULTY=peaceful \
--env MEMORY=3072M \
--env SERVER_NAME="Mount Rushmore" \
-p 25565:25565 \
-v /opt/minecraft:/data \
${var.images["minecraft"]}

ExecStop=-/usr/bin/docker stop minecraft
ExecStop=/opt/world-pusher.sh /opt/minecraft/world ${var.s3_bucket}/world.tgz

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
}

# data "ignition_systemd_unit" "world_push" {
#   name = "world-push.service"

#   content = <<EOF
# [Unit]
# Description=World push
# Wants=network-online.target
# Before=shutdown.target reboot.target halt.target kexec.target


# [Service]
# Type=oneshot
# RemainAfterExit=yes
# ExecStart=-/bin/true
# ExecStop=/opt/world-pusher.sh /opt/minecraft/world ${var.s3_bucket}/world.tgz

# [Install]
# WantedBy=multi-user.target
# EOF
# }

data "ignition_systemd_unit" "registrar" {
  name = "registrar.service"

  content = <<CONTENT
[Unit]
Description=Registrar container - register instance ip with route53

[Service]
Type=oneshot
RemainAfterExit=true
User=core
Environment="PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
ExecStartPre=-/usr/bin/docker rm -f registrar

ExecStart=/usr/bin/docker run --name registrar \
--restart=on-failure:10 \
${var.images["registrar"]} mc.lossanarch.com

ExecStop=-/usr/bin/docker stop registrar

[Install]
WantedBy=multi-user.target
CONTENT
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
        ${var.images["awscli"]} \
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

/usr/bin/tar -cvzf /tmp/world.tgz -C "$LOCATION" .

s3_push() {
    # shellcheck disable=SC2086,SC2154,SC2016
    /usr/bin/docker run \
        --volume /tmp:/tmp \
        --network=host \
        --env LOCATION=$LOCATION \
        --env LOCATION_ESCAPED=$LOCATION_ESCAPED \
        --env DESTINATION=$DESTINATION \
        --entrypoint=/bin/bash \
        ${var.images["awscli"]} \
        -c '
            set -e
            set -o pipefail
            REGION=$(wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone | sed '"'"'s/[a-zA-Z]$//'"'"')
            /usr/bin/aws --region="$REGION" s3 cp /tmp/world.tgz s3://"$DESTINATION"
        '
}

until s3_push; do
    echo "failed to push to S3; retrying in 5 seconds"
    sleep 5
done
CONTENT

  }
}

