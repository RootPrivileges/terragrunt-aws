# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//networking/private-subnet-with-nat?ref=v0.3.0"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "management_account" {
  config_path = "../../../../../../accounts/management"
}

dependency "management_vpc" {
  config_path = "../../../_vpc"
}

dependency "management_tier_1_dmz" {
  config_path = "../../public-subnets/tier-1-dmz"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  account_id                    = dependency.management_account.outputs.account_id
  acl_rule_number               = 10
  public_subnet_acl_id          = dependency.management_tier_1_dmz.outputs.acl_id
  public_subnet_acl_rule_number = 10
  public_subnet_cidr_block      = dependency.management_tier_1_dmz.outputs.cidr_block
  public_subnet_id              = dependency.management_tier_1_dmz.outputs.subnet_id
  public_subnet_name            = "tier-1-dmz"
  subnet_cidr                   = "10.200.110.0/24"
  subnet_name                   = "${basename(basename(get_terragrunt_dir()))}"
  vpc_id                        = dependency.management_vpc.outputs.vpc_id
}
