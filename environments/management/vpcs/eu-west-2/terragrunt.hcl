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

  # Be aware of the pitfalls in the README / detailed on
  # https://registry.terraform.io/modules/hashicorp/subnets/cidr/1.0.0
  # if changing these assignments after the VPC has been created

  private_subnets = {
    tier-2-application = {
      cidr_size               = "large" # 126 usable
      availability_zones      = ["a", "b", "c"]
      public_subnet_name      = "tier-1-dmz"
      private_acl_rule_number = 10
      public_acl_rule_number  = 10
    },
    tier-3-database = {
      cidr_size          = "medium" # 62 usable
      availability_zones = ["a", "b", "c"]
    }
  }

  public_subnets = {
    tier-1-dmz = {
      cidr_size          = "small" # 14 usable
      availability_zones = ["a", "b", "c"]
    },
  }
}
