# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//iam/groups/administrators"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "organisation" {
  config_path = "../../../organisation"
}

dependency "management_account" {
  config_path = "../../../accounts/management"
}

dependency "production_account" {
  config_path = "../../../accounts/production"
}

dependency "preprod_account" {
  config_path = "../../../accounts/preprod"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  assume_terragrunt_data_reader_role_policy_arn = dependency.organisation.outputs.assume_terragrunt_data_reader_role_policy_arn
  billing_role_policy_arn                       = dependency.organisation.outputs.billing_role_policy_arn
  management_admin_role_policy_arn              = dependency.management_account.outputs.admin_role_policy_arn
  organisation_admin_role_policy_arn            = dependency.organisation.outputs.organisation_admin_role_policy_arn
  preprod_admin_role_policy_arn                 = dependency.preprod_account.outputs.admin_role_policy_arn
  production_admin_role_policy_arn              = dependency.production_account.outputs.admin_role_policy_arn
}
