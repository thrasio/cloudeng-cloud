import os
import sys
import boto3

from ruamel.yaml import YAML
from sealer.internal.kms_helper import encrypt_secret, fetch_kms_id, initialize_kms_session
from sealer.internal.repo_structure import (
    generate_full_secret_name,
    generate_path,
    lookup_account_id,
)


def update_file(kms_client, kms_key_id, answers):
    path = generate_path(answers["account_name"], answers["instance_tier"])
    full_secret_name = generate_full_secret_name(answers)
    namespace = answers["namespace"]

    try:
        with open(f"{path}/secrets.yaml", "r+") as secrets_file:
            yaml = YAML()
            data = yaml.load(secrets_file)

            root = data["secrets"]

            if full_secret_name not in root:

                root[full_secret_name] = {
                    "description": f"Generated secrets for the {namespace} namespace. "
                    + "Note: These secrets should only be updated using the sealed secrets terraform module",
                    "tags": {},
                    "entries": {},
                }

            # Confirm that the secret is
            entries = root[full_secret_name]["entries"]
            secret_key = answers["secret_key"]
            plaintext_secret = answers["secret_value"]
            entries[secret_key] = encrypt_secret(kms_client, kms_key_id, full_secret_name, secret_key, plaintext_secret)

            secrets_file.seek(0)
            yaml.dump(data, secrets_file)
            secrets_file.truncate()

    except IOError as e:
        logging.error(e)
        return False


if __name__ == "__main__":
    # namespace
    # account_name
    # instance_tier
    # secret_name
    # secret_key
    # secret_value
    answers = {}
    answers["namespace"] = sys.argv[1]
    answers["account_name"] = sys.argv[2]
    answers["instance_tier"] = "prod" if "prod" in answers["account_name"] else "dev"
    answers["secret_name"] = sys.argv[3]
    answers["secret_key"] = sys.argv[4]
    answers["secret_value"] = sys.argv[5]
    os.chdir("../")

    account_id = lookup_account_id(answers["account_name"])
    session = boto3.Session()

    # Initialize KMS
    kms_client = session.client("kms")
    kms_key_id = fetch_kms_id(kms_client)

    if not kms_key_id:
        print(
            f"No KMS key with alias/sealed-secrets exists in this account."
            + "Run the sealed-secrets module at least once before adding secrets."
        )
        raise Exception()

    # Write the file
    update_file(kms_client, kms_key_id, answers)
