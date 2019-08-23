# terragrunt-aws-init

## Motivation

This script is designed to set up a repeatable minimal AWS deployment from scratch - creating an organisation from the provided primary account, with consolidated billing enabled, and creating multiple AWS sub-accounts within the organisation to logically segregate resources by environment.

It is based on the (outdated) script at https://github.com/liatrio/aws-accounts-terraform, and builds upon the work detailed in the following blog posts:

- https://www.liatrio.com/blog/secure-aws-account-structure-with-terraform-and-terragrunt
- https://medium.com/@EmiiKhaos/automated-aws-account-initialization-with-terraform-and-onelogin-saml-sso-1301ff4851ab
- https://medium.com/@EmiiKhaos/part-2-automated-aws-multi-account-setup-with-terraform-and-onelogin-sso-44baaf563877
