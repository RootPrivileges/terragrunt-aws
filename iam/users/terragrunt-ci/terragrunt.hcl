# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//iam/users/terragrunt"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "organisation" {
  config_path = "../../../organisation"
}

dependency "terragrunt_group" {
  config_path  = "../../groups/terragrunt"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  username = "terragrunt.ci"
}
