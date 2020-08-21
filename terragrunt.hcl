locals {
  aws_region              = "eu-west-2"
  billing_alarm_currency  = "USD"
  billing_alarm_threshold = "5"
  domain                  = "domain.com"
  keybase                 = "keybase-username"

  # Don't edit below

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl", "${path_relative_from_include()}/empty.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl", "${path_relative_from_include()}/empty.hcl"))

  # Automatically load account-level variables
  az_vars = read_terragrunt_config(find_in_parent_folders("availability_zone.hcl", "${path_relative_from_include()}/empty.hcl"))
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

# Generate terraform.tf file dynamically
generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite"
  contents  = file("${get_parent_terragrunt_dir()}/terraform.block")
}

# Generate provider.tf file dynamically
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = file("${get_parent_terragrunt_dir()}/provider.block")
}

# Configure root level variables that all resources inherit
# This shouldn't need to be edited
inputs = merge(
  {
    admin_email                  = "aws.administrator@${local.domain}"
    audit_logs_bucket_name       = "logging.${local.domain}"
    aws_region                   = local.aws_region
    billing_alarm_currency       = local.billing_alarm_currency
    billing_alarm_threshold      = local.billing_alarm_threshold
    cloudtrail_bucket_name       = "cloudtrail.${local.domain}"
    domain                       = local.domain
    keybase                      = local.keybase
    tfstate_global_bucket        = "tfstate.${local.domain}"
    tfstate_global_bucket_region = local.aws_region
    tfstate_global_dynamodb      = "tflocks.${local.domain}"
  },
  local.environment_vars.locals,
  local.region_vars.locals,
  local.az_vars.locals,
)

terragrunt_version_constraint = ">= 0.23.31"
