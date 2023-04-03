#!/usr/bin/env bash
set -o errexit -o errtrace -o nounset -o pipefail

# Guard against someone running the make script from inside the container.
if [[ "${RUNNING_IN_CONTAINER:-}" == "1" ]]; then
    exit 0
fi

# Ensure host dependencies are installed.
dependencies=(
    "docker"
    "gpg"
    "make"
)
for dependency in "${dependencies[@]}"; do
    if command -v "${dependency}" >/dev/null 2>&1; then
        echo "Found required dependency: ${dependency}."
    else
        echo "Unable to find dependency: ${dependency}."
        exit 1
    fi
done

if [[ -f .sops.yaml ]]; then
    # Ensure there's a PGP key for this repo.
    key_name="${APP_OWNER?}/${APP_NAME?}"
    if gpg --list-secret-keys "${key_name}" &>/dev/null; then
        echo "Found PGP key (${key_name}) for encrypted secrets."
    else
        echo "Unable to find PGP key (${key_name}) for encrypted secrets."
        choice=$(gum choose \
            "Create new key" \
            "Import existing key" \
            "Exit")
        if [[ "${choice}" == "Create new key" ]]; then
            gpg_home=$(gpgconf --list-dirs homedir)
            if [[ ! -d "${gpg_home}" ]]; then
                echo "GPG home '${gpg_home}' does not exist - exiting."
                exit 1
            fi

            mkdir -p "${gpg_home}/sops-keys"
            chmod -R 700 "${gpg_home}/sops-keys"

            key_path="${gpg_home}/sops-keys/${key_name}.asc"
            if [[ -f $key_path ]]; then
                echo "Key already exists: ${key_path} - exiting."
                exit 1
            fi

            # Prompt for email.
            key_email=$(gum input --header="Key email:" --value="$(git config user.email)")
            key_comment="SOPS encryption key"

            echo "Creating GPG key..."
            # cspell: words subkey
            gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Expire-Date: 0
Name-Comment: $key_comment
Name-Real: $key_name
Name-Email: $key_email
EOF
            # Export the key to $gpg_home and ensure correct permissions.
            mkdir -p "$(dirname "$key_path")"
            chmod -R 700 "$(dirname "$key_path")"
            key_fingerprint=$(gpg --list-secret-keys "$key_name" | grep -E "[A-Z0-9]{40}" | xargs)
            gpg --export-secret-keys --armor "$key_fingerprint" >"$key_path"
            chmod -R 600 "$key_path"

            # Configure SOPS.
            cat <<EOF >.sops.yaml
---
creation_rules:
  - path_regex: etc/local/.*
    pgp: $key_fingerprint
  - path_regex: etc/test/.*
    pgp: $key_fingerprint
EOF

            # Report success.
            echo ""
            echo ""
            echo "################################################################################"
            echo ""
            echo "Created PGP key ($key_name) for encrypted secrets:"
            echo " - Fingerprint: $key_fingerprint"
            echo " - Backup path: $key_path"
            echo ""
            echo "Once this repo has been pushed to GitHub, please run:"
            echo ""
            echo "    gh secret set SOPS_GPG_PRIVATE_KEY < $key_path"
            echo ""
            echo "################################################################################"
            echo ""
            echo ""
        elif [[ "${choice}" == "Import existing key" ]]; then
            key_file=$(gum file --file)
            if [[ "${key_file}" == "" ]]; then
                echo "Empty key path - exiting."
                exit 1
            fi
            echo "Importing $key_file ..."
            gpg --import "$key_file"
            echo ""
        else
            echo "Unable to continue without a key - exiting."
            echo "Note: to bypass this check, remove .sops.yaml and any secrets.yml files in ./etc"
            exit 1
        fi
    fi
fi

# Build the image.
image_name=$(docker compose convert --images app)
image_id=$(docker images -q "${image_name}")
if [[ "${image_id}" == "" ]]; then
    echo "Building ${image_name}..."
    echo ""
    make docker-build
fi
