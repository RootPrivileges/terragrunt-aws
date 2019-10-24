locals {
  aws_region = "eu-west-2"
  domain     = "domain.com"
  keybase    = "keybase-username"
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"

  config = {
    encrypt        = true
    bucket         = "tfstate.${local.domain}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = "tflocks.${local.domain}"
  }
}

# Configure root level variables that all resources inherit
inputs = {
  admin_email                  = "aws.administrator@${local.domain}"
  audit_logs_bucket_name       = "logging.${local.domain}"
  aws_region                   = local.aws_region
  domain                       = local.domain
  cloudtrail_bucket_name       = "cloudtrail.${local.domain}"
  keybase                      = local.keybase
  tfstate_global_bucket        = "tfstate.${local.domain}"
  tfstate_global_bucket_region = local.aws_region
  tfstate_global_dynamodb      = "tflocks.${local.domain}"
}
