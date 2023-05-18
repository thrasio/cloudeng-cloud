#!/usr/bin/env bash

cd "$(dirname "$0")"

# Fetch all the `app_secrets`:
# aws-vault exec dabs-dev -- aws secretsmanager list-secrets | jq ".SecretList | .[].Name" -r | grep "app_secrets"
declare -a NAMESPACES=(
#    "psych"
#    "jungle-scout-connector"
#    "product-catalog-akeneo"
    "tmi-user-service"
#    "plaid-integration-service"
#    "amazon-fead-connector"
#    "data-connector-shims"
#    "klaviyo-connector"
#    "amazon-sp-api-connector"
#    "product-pricing-service"
    "thrasahead"
#    "bid-management"
#    "quartile-api-connector"
#    "tmi-ui"
#    "sc-workflow-automation-service"
#    "stores-management"
#    "shark-retail"
#    "sc-product-test-requests"
#    "acenda-data-connector"
#    "stackline-connector"
#    "product-catalog"
#    "ap-data-ingestion"
#    "finsc-uk-fbm-api-connector"
)

INSTANCE_TIER="prod"
SECRET_NAME="app_secrets"
ACCOUNT_NAME="dabs-${INSTANCE_TIER}"

for NAMESPACE in "${NAMESPACES[@]}"; do

    SECRET_ID="${INSTANCE_TIER}/${NAMESPACE}/${SECRET_NAME}"
    echo "Importing ${SECRET_ID}"

    SECRET_ARN=$(aws-vault exec ${ACCOUNT_NAME} -- aws secretsmanager describe-secret --secret-id ${SECRET_ID} --query ARN --output text)
    SECRET_VALUES=$(aws-vault exec ${ACCOUNT_NAME} -- aws secretsmanager get-secret-value --secret-id ${SECRET_ID} --query SecretString --output text)

    # Note -- You can only import once, might need to comment this out if something goes wrong with the import.
    pushd "../${ACCOUNT_NAME}/us-east-1/${INSTANCE_TIER}/secrets"
    aws-vault exec ${ACCOUNT_NAME} -- terragrunt import "aws_secretsmanager_secret.secret_manager_secrets[\"${SECRET_ID}\"]" ${SECRET_ARN}
    popd

    echo ${SECRET_VALUES} | jq -c -r "keys | .[]" | while read KEY;
    do
        SECRET_VALUE=$(echo ${SECRET_VALUES} | jq -c -r ".[\"${KEY}\"]")

        aws-vault exec ${ACCOUNT_NAME} -- pipenv run python import.py ${NAMESPACE} ${ACCOUNT_NAME} ${SECRET_NAME} ${KEY} ${SECRET_VALUE}
    done
done
