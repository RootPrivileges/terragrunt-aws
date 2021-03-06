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
    echo "  - The default account will be converted to an organisation"
    echo "  - Management, Production and Preprod sub-accounts will be created"
    echo "  - Various groups, including administrators, developers, finance, terragrunt and users will be created"
    echo "  - An IAM user will be created in the organisation account with the necessary permissions to run terragrunt"
    echo "  - An IAM administrator user will be created"
    echo "  *** MUST BE INITIALLY RUN WITH CREDENTIALS FOR A SPECIALLY-PROVISIONED USER IN THE ORGANISATION ACCOUNT ***"
    echo ""
    echo "USAGE:"
    echo "  ${0} -a <access key> -s <secret key> -k <keybase profile> [-l <local_modules_directory>] [-r <region>]"
    echo ""
    echo "OPTIONAL ARGUMENTS:"
    echo "  -l   Use a local folder as the source for Terragrunt modules e.g. ~/Code/terraform/modules"
    echo "  -r   Override the default AWS region (eu-west-2)"
    echo ""
    echo "Requirements:"
    echo "  - Terraform"
    echo "  - Terragrunt"
    echo "  - Keybase"
}

function check_prereqs {
    MISSING_PREREQ=0

    if ! [ -x "$(command -v terraform)" ]; then
        echo "Script requires terraform, but it is not installed.  Aborting."
        MISSING_PREREQ=1
    fi
    if ! [ -x "$(command -v terragrunt)" ]; then
        echo "Script requires terragrunt, but it is not installed.  Aborting."
        MISSING_PREREQ=1
    fi
    if ! [ -x "$(command -v keybase)" ]; then
        echo "Script requires keybase, but it is not installed.  Aborting."
        MISSING_PREREQ=1
    fi

    if [[ "${MISSING_PREREQ}" -gt 0 ]]; then
        exit 1
    fi
}

check_prereqs

while getopts "a:k:l:r:s:dh" option; do
    case ${option} in
        a ) ACCESS_KEY=$OPTARG;;
        d ) DEV_MODE=1;;
        k ) KEYBASE_PROFILE=$OPTARG;;
        l ) LOCAL_MODULES_DIR=$OPTARG;;
        r ) DEFAULT_REGION=$OPTARG;;
        s ) SECRET_KEY=$OPTARG;;
        h )
            usage
            exit 0
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            usage
            exit 1
            ;;
    esac
done

if [ -z "$DEV_MODE" ]; then
    DEV_MODE=0
    AUTO_APPROVE="-auto-approve"
fi

if [[ -z "${ACCESS_KEY}" ]]; then
    echo "Please provide the terragrunt.init user's access key with -a <access key>" 1>&2
    VALIDATION_ERROR=1
fi
if [[ -z "${SECRET_KEY}" ]]; then
    echo "Please provide the terragrunt.init user's secret key with -s <secret key>" 1>&2
    VALIDATION_ERROR=1
fi
if [[ -z "${KEYBASE_PROFILE}" ]]; then
    echo "Please provide the keybase username as -k <keybase profile> " 1>&2
    VALIDATION_ERROR=1
fi
if [[ -n "${VALIDATION_ERROR}" ]]; then
    echo ""
    exit 1
fi

if [[ -n "${LOCAL_MODULES_DIR}" ]]; then
    TG_SOURCE="--terragrunt-source ${LOCAL_MODULES_DIR}"
fi


export AWS_DEFAULT_REGION=${DEFAULT_REGION}

function export_init_user_keys {
    echo ""
    echo "USING PROVIDED CREDENTIALS"
    echo ""
    export AWS_ACCESS_KEY_ID=${ACCESS_KEY}
    export AWS_SECRET_ACCESS_KEY=${SECRET_KEY}
}

function export_admin_user_keys {
    echo ""
    echo "USING ADMIN CREDENTIALS"
    echo ""
    export AWS_ACCESS_KEY_ID=${ADMIN_ACCESS_KEY}
    export AWS_SECRET_ACCESS_KEY=${ADMIN_SECRET_KEY}
}

function pushd () {
    command pushd "$@" > /dev/null
}

function popd () {
    command popd "$@" > /dev/null
}


export_init_user_keys


echo -e "\n=== CREATING ORGANISATION ===\n"
pushd ./first-run/convert-to-organisation
if [[ -n "${TG_SOURCE}" ]]; then
    TG_SOURCE_MODULE="${TG_SOURCE}//utility/organisation/convert-to-organisation"
fi
terragrunt init ${TG_SOURCE_MODULE}
terragrunt apply ${TG_SOURCE_MODULE} ${AUTO_APPROVE}
popd


echo -e "\n=== DEPLOYING INFRASTRUCTURE ===\n"
if [[ -n "${AUTO_APPROVE}" ]]; then
    AUTO_APPROVE="--terragrunt-non-interactive"
fi
terragrunt apply-all --terragrunt-exclude-dir "first-run/*" ${TG_SOURCE} ${AUTO_APPROVE}


echo -e "\n=== COLLECTING OUTPUTS ===\n"
pushd ./organisation
if [[ -n "${TG_SOURCE}" ]]; then
    TG_SOURCE_MODULE="${TG_SOURCE}//organisation"
fi
ACCOUNT_ID=$(terragrunt output ${TG_SOURCE_MODULE} account_id)
SUPPORT_USERNAME=$(terragrunt output ${TG_SOURCE_MODULE} support_user_name)
SUPPORT_PASSWORD=$(terragrunt output ${TG_SOURCE_MODULE} support_user_password | base64 --decode | keybase pgp decrypt)
popd

pushd ./accounts/management
if [[ -n "${TG_SOURCE}" ]]; then
    TG_SOURCE_MODULE="${TG_SOURCE}//account"
fi
MANAGEMENT_ID=$(terragrunt output ${TG_SOURCE_MODULE} account_id)
popd

pushd ./accounts/production
if [[ -n "${TG_SOURCE}" ]]; then
    TG_SOURCE_MODULE="${TG_SOURCE}//account"
fi
PRODUCTION_ID=$(terragrunt output ${TG_SOURCE_MODULE} account_id)
popd

pushd ./accounts/preprod
if [[ -n "${TG_SOURCE}" ]]; then
    TG_SOURCE_MODULE="${TG_SOURCE}//account"
fi
PREPROD_ID=$(terragrunt output ${TG_SOURCE_MODULE} account_id)
popd

pushd ./iam/users/terragrunt-ci
if [[ -n "${TG_SOURCE}" ]]; then
    TG_SOURCE_MODULE="${TG_SOURCE}//iam/users/terragrunt"
fi
TERRAGRUNT_GITLAB_ACCESS_KEY=$(terragrunt output ${TG_SOURCE_MODULE} terragrunt_user_access_key)
TERRAGRUNT_GITLAB_SECRET_KEY=$(terragrunt output ${TG_SOURCE_MODULE} terragrunt_user_secret_key | base64 --decode | keybase pgp decrypt)
popd

pushd ./iam/users/administrator
if [[ -n "${TG_SOURCE}" ]]; then
    TG_SOURCE_MODULE="${TG_SOURCE}//iam/users/administrator"
fi
ADMIN_USERNAME=$(terragrunt output ${TG_SOURCE_MODULE} admin_username)
ADMIN_PASSWORD=$(terragrunt output ${TG_SOURCE_MODULE} admin_user_password | base64 --decode | keybase pgp decrypt)
ADMIN_ACCESS_KEY=$(terragrunt output ${TG_SOURCE_MODULE} admin_user_access_key)
ADMIN_SECRET_KEY=$(terragrunt output ${TG_SOURCE_MODULE} admin_user_secret_key | base64 --decode | keybase pgp decrypt)
popd


if [ "$DEV_MODE" -eq 0 ]; then
    echo -e "\n=== DELETING terragrunt.init IAM USER ===\n"

    export_admin_user_keys

    pushd ./first-run/delete-terragrunt-init
    if [[ -n "${TG_SOURCE}" ]]; then
        TG_SOURCE_MODULE="${TG_SOURCE}//utility/iam/import-unmanaged-iam-user"
    fi
    terragrunt init ${TG_SOURCE_MODULE}
    terragrunt import ${TG_SOURCE_MODULE} --terragrunt-iam-role "arn:aws:iam::${ACCOUNT_ID}:role/OrgTerragruntAdministratorAccessRole" aws_iam_user.user terragrunt.init

    # Well, this was super annoying... "terraform import" doesn't pick up force_destroy preventing the user being deleted due to unmanaged access keys
    # https://github.com/terraform-providers/terraform-provider-aws/issues/7859
    #
    # Running apply makes terraform see that the force_destroy flag is set for the user, and updates accordingly
    terragrunt apply ${TG_SOURCE_MODULE} ${AUTO_APPROVE} --terragrunt-iam-role "arn:aws:iam::${ACCOUNT_ID}:role/OrgTerragruntAdministratorAccessRole"

    terragrunt destroy ${TG_SOURCE_MODULE} ${AUTO_APPROVE} --terragrunt-iam-role "arn:aws:iam::${ACCOUNT_ID}:role/OrgTerragruntAdministratorAccessRole"
    popd
fi

echo -e "\n=== INITIALISATION COMPLETE ==="
echo "Console login                    : https://${ACCOUNT_ID}.signin.aws.amazon.com/console"
echo "----------------------------------------------------------------"
echo "Role Switch Links"
echo "Organisation Administrator       :  https://signin.aws.amazon.com/switchrole?account=${ACCOUNT_ID}&roleName=OrgAdministratorAccessRole&displayName=OrgAccount%20-%20Administrator"
echo "Billing                          :  https://signin.aws.amazon.com/switchrole?account=${ACCOUNT_ID}&roleName=OrgBillingAccessRole&displayName=OrgAccount%20-%20Billing"
echo "Support                          :  https://signin.aws.amazon.com/switchrole?account=${ACCOUNT_ID}&roleName=OrgSupportRole&displayName=OrgAccount%20-%20Support"
echo "Terragrunt Administrator         :  https://signin.aws.amazon.com/switchrole?account=${ACCOUNT_ID}&roleName=OrgTerragruntAdministratorAccessRole&displayName=OrgAccount%20-%20Terragrunt%20Administrator"
echo "Terragrunt Data Admininstrator   :  https://signin.aws.amazon.com/switchrole?account=${ACCOUNT_ID}&roleName=OrgTerragruntDataAdministratorAccessRole&displayName=OrgAccount%20-%20Terragrunt%20Data%20Admin"
echo "Terragrunt Data Reader           :  https://signin.aws.amazon.com/switchrole?account=${ACCOUNT_ID}&roleName=OrgTerragruntDataReaderAccessRole&displayName=OrgAccount%20-%20Terragrunt%20Data%20Read"
echo "Management Administrator         :  https://signin.aws.amazon.com/switchrole?account=${MANAGEMENT_ID}&roleName=ManagementAdministratorAccessRole&displayName=Management%20-%20Administrator"
echo "Production Administrator         :  https://signin.aws.amazon.com/switchrole?account=${PRODUCTION_ID}&roleName=ProductionAdministratorAccessRole&displayName=Production%20-%20Administrator"
echo "Preprod Administrator            :  https://signin.aws.amazon.com/switchrole?account=${PREPROD_ID}&roleName=PreprodAdministratorAccessRole&displayName=Preprod%20-%20Administrator"
echo "Preprod Power User               :  https://signin.aws.amazon.com/switchrole?account=${PREPROD_ID}&roleName=PreprodPowerUserAccessRole&displayName=Preprod%20-%20Power%20User"
echo "----------------------------------------------------------------"
echo "Administrator username           : " $ADMIN_USERNAME
echo "Administrator password           : " $ADMIN_PASSWORD
echo "Administrator access key         : " $ADMIN_ACCESS_KEY
echo "Administrator secret key         : " $ADMIN_SECRET_KEY
echo "----------------------------------------------------------------"
echo "terragrunt.ci access key         : " $TERRAGRUNT_GITLAB_ACCESS_KEY
echo "terragrunt.ci secret key         : " $TERRAGRUNT_GITLAB_SECRET_KEY
echo "----------------------------------------------------------------"
echo "Support username                 : " $SUPPORT_USERNAME
echo "Support password                 : " $SUPPORT_PASSWORD
