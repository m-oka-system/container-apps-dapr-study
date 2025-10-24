#! /bin/bash

# GitHub Login
gh auth login

# Register Secrets
gh secret set -f .secrets
gh secret set APP_PRIVATE_KEY <"$(git rev-parse --show-toplevel)/infra/github-app-private-key.pem"

# Register Variables
gh variable set -f variables
