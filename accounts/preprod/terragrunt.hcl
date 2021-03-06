# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//account"
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
  account_name          = "preprod"
  account_email_slug    = "aws.preprod"
  audit_logs_bucket_arn = dependency.organisation.outputs.audit_logs_bucket_arn
  audit_logs_bucket_id  = dependency.organisation.outputs.audit_logs_bucket_id
  org_account_id        = dependency.organisation.outputs.account_id
  org_detector_ids      = dependency.organisation.outputs.detector_ids
}
