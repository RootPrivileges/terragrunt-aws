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
  account_name                     = dependency.management_account.outputs.account_name
  aws_region                       = "eu-west-2"
  cidr_block                       = "10.200.0.0/16"
  vpc_flow_logs_publisher_role_arn = dependency.management_account.outputs.vpc_flow_logs_publisher_role_arn

  private_subnets = {
    tier-2-application = {
      cidr                    = "10.200.110.0/24"
      availability_zones      = ["a", "b", "c"]
      public_subnet_name      = "tier-1-dmz"
      private_acl_rule_number = 10
      public_acl_rule_number  = 10
    },
    tier-3-database = {
      cidr               = "10.200.210.0/24"
      availability_zones = ["a", "b", "c"]
    }
  }

  public_subnets = {
    tier-1-dmz = {
      cidr               = "10.200.10.0/24"
      availability_zones = ["a", "b", "c"]
    },
  }
}
