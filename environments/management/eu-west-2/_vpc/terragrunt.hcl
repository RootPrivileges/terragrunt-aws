# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//networking/vpc"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "management_account" {
  config_path = "../../../../accounts/management"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  account_id                       = dependency.management_account.outputs.account_id
  cidr_block                       = "10.200.0.0/16"
  vpc_flow_logs_publisher_role_arn = dependency.management_account.outputs.vpc_flow_logs_publisher_role_arn
}
