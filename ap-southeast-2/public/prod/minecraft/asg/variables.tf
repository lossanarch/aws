variable "name" {}

variable "user_data_base64" {}

variable "data_bucket_arn" {}

variable "security_groups" {
  type = list(string)
}

variable "key_pair_name" {}
