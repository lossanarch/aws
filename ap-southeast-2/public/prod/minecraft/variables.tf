variable "s3_bucket" {
  default = "lossanarch-minecraft-data"
}

variable "images" {
  default = {
    awscli    = "quay.io/coreos/awscli:025a357f05242fdad6a81e8a6b520098aa65a600"
    minecraft = "itzg/minecraft-server:latest"
    registrar = "lossanarch/registrar:0.1.0"
  }
}

variable "minecraft_version" {
  default = "1.14.4"
}
