# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//iam/users/administrator"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "organisation" {
  config_path = "../../../organisation"
}

dependency "administrators_group" {
  config_path  = "../../groups/administrators"
}

dependency "terragrunt_group" {
  config_path  = "../../groups/terragrunt"
}

dependency "users_group" {
  config_path  = "../../groups/users"
}

locals {
  global_vars = read_terragrunt_config(find_in_parent_folders())
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  administrators_group_name = dependency.administrators_group.outputs.name
  email_address             = local.global_vars.inputs.admin_email
  enable_terragrunt         = true
  terragrunt_group_name     = dependency.terragrunt_group.outputs.name
  users_group_name          = dependency.users_group.outputs.name
}
