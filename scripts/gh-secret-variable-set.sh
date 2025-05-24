#! /bin/bash

# GitHub Login
gh auth login

# Register Secrets
gh secret set -f .secrets

# Register Variables
gh variable set -f variables
