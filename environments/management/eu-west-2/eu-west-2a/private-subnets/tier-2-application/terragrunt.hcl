# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:rootprivileges/terragrunt-aws-modules.git//networking/private-subnet-with-nat?ref=v0.1.7"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../../_vpc", "../../public-subnets/tier-1-public"]
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  acl_rule_number               = 10
  public_subnet_acl_rule_number = 10
  public_subnet_name            = "tier-1-public"
  subnet_cidr                   = "10.200.110.0/24"
  subnet_name                   = "${basename(basename(get_terragrunt_dir()))}"
}
