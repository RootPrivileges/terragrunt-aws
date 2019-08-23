# terragrunt-aws-init

## Motivation

This script is designed to set up a repeatable minimal AWS deployment from scratch - creating an organisation from the provided primary account, with consolidated billing enabled, and creating multiple AWS sub-accounts within the organisation to logically segregate resources by environment.

It is based on the (outdated) script at https://github.com/liatrio/aws-accounts-terraform, and builds upon the work detailed in the following blog posts:

- https://www.liatrio.com/blog/secure-aws-account-structure-with-terraform-and-terragrunt
- https://medium.com/@EmiiKhaos/automated-aws-account-initialization-with-terraform-and-onelogin-saml-sso-1301ff4851ab
- https://medium.com/@EmiiKhaos/part-2-automated-aws-multi-account-setup-with-terraform-and-onelogin-sso-44baaf563877

## Prerequisites

- Terraform >= 0.12, on path
- Terragrunt >= v0.9.14, on path

## Execution

1. Create the master AWS account:

- Ideally, use email address of aws.master@domain.com to keep in line with other (default) values set by the script
- Set account name as master, to keep in line with other account names

2. Wait for AWS activation email to arrive

- Otherwise, features like S3 won't work for storing Terraform state

3. Clone this git repository (it is _not_ necessary to also clone https://github.com/RootPrivileges/terragrunt-aws-init-modules unless changing that code)
4. Modify the `locals` section in the [terragrunt.hcl](terragrunt.hcl) file in the root folder to set the desired domain
5. Create `TerragruntInit` policy in IAM, and copy the JSON in [this file](TerragruntInit-IAM-Policy.txt) to that policy
6. Create a `terragrunt.init` user in IAM, with programmatic access enabled. Then copy access and secret key generate by AWS
7. Execute:

```
./account-init.sh -a <access key> -s <secret key>
```

### Optional flags

- To use a local folder as the source of the modules, add `-l <path to modules>`
- To override the default AWS region, use `-r`
