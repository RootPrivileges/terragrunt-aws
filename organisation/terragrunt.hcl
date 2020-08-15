# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//organisation"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "first_run" {
  config_path = "../first-run/convert-to-organisation"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  organisation_admin_role_policy_arn = dependency.first_run.outputs.organisation_admin_role_policy_arn
}
