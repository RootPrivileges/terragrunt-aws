#!/bin/bash

# Based on script from https://github.com/liatrio/aws-accounts-terraform
# Builds on the work of the following blog posts:
#   - https://www.liatrio.com/blog/secure-aws-account-structure-with-terraform-and-terragrunt
#   - https://medium.com/@EmiiKhaos/automated-aws-account-initialization-with-terraform-and-onelogin-saml-sso-1301ff4851ab
#   - https://medium.com/@EmiiKhaos/part-2-automated-aws-multi-account-setup-with-terraform-and-onelogin-sso-44baaf563877

set -e

DEFAULT_REGION='eu-west-2'

function usage {
    echo "DESCRIPTION:"
    echo "  Script for initializing a basic AWS account structure:"
    echo "  - An organisation will be configured"
    echo "  - Management, Production and Staging accounts will be created"
    echo "  - An IAM user will be created in the Master organisation with the necessary permissions to run terragrunt"
    echo "  *** MUST BE INITIALLY RUN WITH CREDENTIALS FOR A SPECIALLY-PROVISIONED USER IN THE MASTER ACCOUNT ***"
    echo "  *** THIS USER WILL BE DELETED AT THE END OF THE RUN, UNLESS OTHERWISE INSTRUCTED  ***"
    echo ""
    echo "USAGE:"
    echo "  ${0} -a <access key> -s <secret key> [-l <local_modules_directory>] [-r <region>]"
    echo ""
    echo "OPTIONAL ARGUMENTS:"
    echo "  -l   Use a local folder as the source for Terragrunt modules e.g. ~/Code/terraform/modules"
    echo "  -r   Override the default AWS region (eu-west-2)"
    echo ""
    echo "Requirements:"
    echo "  - Terraform"
    echo "  - Terragrunt"
}
