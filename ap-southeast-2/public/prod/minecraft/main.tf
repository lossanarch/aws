module "environment" {
  source = "../"
}

module "minecraft" {

    source = "./asg"


    name = "minecraft"

    data_bucket_arn = aws_s3_bucket.data.arn

    user_data_base64 = base64encode(data.ignition_config.minecraft.rendered)

    security_groups = [
    	aws_security_group.minecraft.id,
    ]

    key_pair_name = module.environment.key_pairs["me"]

}
