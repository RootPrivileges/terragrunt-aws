# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//account?ref=v0.3.0"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "organisation" {
  config_path = "../../organisation"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  account_name       = "management"
  account_email_slug = "aws.management"
  audit_logs_bucket_arn = dependency.organisation.outputs.audit_logs_bucket_arn
  audit_logs_bucket_id  = dependency.organisation.outputs.audit_logs_bucket_id
  master_account_id     = dependency.organisation.outputs.master_account_id
  master_detector_ids   = dependency.organisation.outputs.master_detector_ids
}
