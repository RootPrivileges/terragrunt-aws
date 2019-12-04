# terragrunt-aws

## Motivation

This script is designed to set up a opinionated, repeatable minimal AWS deployment from scratch - creating an organisation from the provided primary account, with consolidated billing enabled, and then creating multiple AWS sub-accounts within the organisation to logically segregate resources by environment.

Additionally, the installation will be hardened in line with various security recommendations, with MFA enforced on user accounts, the use of IAM Assume roles to grant privileges in the various sub-accounts, CloudTrail, AWS Config and GuardDuty enabled in all regions, and the default VPC hardened by removing default routes and enabling Flow Logs.

The deployed infrastructure does not only make use of Free Tier components, as it is designed to deploy a baseline practical infrastructure to enable faster time to a productive environment, rather than as a demonstration, or reference architecture of "what could be". However, alternatively, the deployment has been designed with the Free support plan in mind, and does not need AWS Support to increase any resource limitations in order to deploy initially.

### Standing on the shoulders of giants

This repository is primarily based on the (now-outdated) script at https://github.com/liatrio/aws-accounts-terraform, and builds upon the work detailed in the following blog posts:

- https://www.liatrio.com/blog/secure-aws-account-structure-with-terraform-and-terragrunt
- https://medium.com/@EmiiKhaos/automated-aws-account-initialization-with-terraform-and-onelogin-saml-sso-1301ff4851ab
- https://medium.com/@EmiiKhaos/part-2-automated-aws-multi-account-setup-with-terraform-and-onelogin-sso-44baaf563877

On top of this starting point, the production-grade guide series at https://gruntwork.io/guides/ further details the principles that have influenced multiple design decisions, as well as reuse of the [AWS Secure-Baseline Terraform modules](https://registry.terraform.io/modules/nozaq/secure-baseline/) from [nozaq](https://github.com/nozaq/).

One break from traditional AWS security hardening guidance, is that there is no dedicated Security account to hold IAM users and audit data. This is instead held within the initial Organisation account.

## Description

After converting the initial AWS account into an organisation, the following accounts are created within the organisation for holding AWS resources:

- Production
- Staging
- Management - for supporting services, such as VPN servers, bastion hosts and CI/CD servers

The following groups are provisioned:

- Administrators
  - Administrator access to Master organisation
  - Administrator access to the 3 sub-accounts
  - Access to Billing in the AWS console
- Terragrunt
  - Administrator access to Master IAM
  - Administrator access to the three sub-accounts
- Developers
  - Administrator access to the Staging account
- Accounting
  - Access to Billing in the AWS console

Users are created in IAM within the Master organisation:

- An initial user is created using the provided username and email address, with administrator privileges in the Master organisation
- A `terragrunt.gitlab` user in the Terragrunt group is also created, for use in CI/CD pipelines

After creation of a user (using Terraform, the console or the CLI), they will need to sign in and add an MFA token to their account before they can perform most actions (including assuming roles).

Multiple S3 buckets are created:

- tfstate.<domain.com> - this holds the Terragrunt remote state and has versioning, access logging and encryption enabled
- cloudtrail.<domain.com> - this holds the CloudTrail output and has the same settings as above, but also has object lock enabled for auditing purposes
- logging.<domain.com> - this holds S3 audit logs, as well as AWS Config data, and has versioning, encryption and object lock enabled

All of these buckets have public access blocked.

## Prerequisites

- Terraform >= 0.12, on path
- Terragrunt >= v0.9.14, on path
- Keybase, installed locally and authenticated

## Execution

1. Create a new AWS account to become the master Organisation:

- Ideally, use email address of aws.master@domain.com to keep in line with other (default) values on accounts created by the script
- Set account name as "master", to keep this in line with other account names

2. Wait for AWS activation email to arrive

- Otherwise, features like S3 won't work for storing Terraform state

3. Enable IAM access for Billing in console settings
4. Enable billing alarm in console settings
5. Enable MFA on the root account, preferably connected to a physical device
6. Clone this git repository (it is _not_ necessary to also clone https://github.com/RootPrivileges/terragrunt-aws-modules unless changing that code)
7. Modify the `locals` section in the [terragrunt.hcl](terragrunt.hcl) file in the root folder to set the desired domain, and the email address of the first administrator (set as their username)
8. Create an initial `terragrunt.init` user in IAM:

- Enable programmatic access
- Assign the AdministratorAccess policy to this new user
- Take a copy of the access key and secret key generated by AWS

9. Execute:

```
./account-init.sh -a <access key> -s <secret key> -k <keybase profile>
```

### Optional flags

- To use a local folder as the source of the modules, add `-l <path to modules>`
- To override the default AWS region, use `-r`
