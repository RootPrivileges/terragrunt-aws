# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//iam/groups/developers?ref=v0.3.0"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "preprod_account" {
  config_path = "../../../accounts/preprod"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  preprod_account_id   = dependency.preprod_account.outputs.account_id
  preprod_account_name = dependency.preprod_account.outputs.account_name
}
