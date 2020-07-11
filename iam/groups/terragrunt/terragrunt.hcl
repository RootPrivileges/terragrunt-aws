# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//iam/groups/terragrunt?ref=v0.3.0"
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

dependency "staging_account" {
  config_path = "../../../accounts/staging"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  assume_terragrunt_administrator_role_policy_arn = dependency.organisation.outputs.assume_terragrunt_administrator_role_policy_arn
  management_org_account_access_role_policy_arn   = dependency.management_account.outputs.org_account_access_role_policy_arn
  production_org_account_access_role_policy_arn   = dependency.production_account.outputs.org_account_access_role_policy_arn
  staging_org_account_access_role_policy_arn      = dependency.staging_account.outputs.org_account_access_role_policy_arn
  terragrunt_data_administrator_policy_arn        = dependency.organisation.outputs.terragrunt_data_administrator_policy_arn
}
