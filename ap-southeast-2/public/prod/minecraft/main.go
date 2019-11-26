locals {
	s3_bucket = "lossanarch-minecraft-data"

	images = {
		awscli = "quay.io/coreos/awscli:025a357f05242fdad6a81e8a6b520098aa65a600"
		minecraft = "itzg/minecraft-server:latest"
	}

	minecraft_version = "1.14.4"
}

module "minecraft" {

    source = "./asg"


    name = "minecraft"

    user_data = data.ignition_config.minecraft.rendered


}
