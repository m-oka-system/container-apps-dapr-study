#! /bin/bash

appName="githubactions"

# Azure Login
az login

# Get the current Azure subscription ID
subscriptionId="$(az account show --query 'id' --output tsv)" && echo "$subscriptionId"

# Create a new Azure Active Directory application
appId="$(az ad app create --display-name "$appName" --query appId --output tsv)" && echo "$appId"

# Create a new service principal for the application
assigneeObjectId="$(az ad sp create --id "$appId" --query id --output tsv)" && echo "$assigneeObjectId"

# Define the roles to assign
roles_to_assign=("Owner" "Storage Blob Data Contributor" "Key Vault Secrets Officer")

# Loop through the roles and assign each one
for role_name in "${roles_to_assign[@]}"; do
  echo "Assigning role: $role_name"
  az role assignment create --role "$role_name" \
    --subscription "$subscriptionId" \
    --assignee-object-id "$assigneeObjectId" \
    --assignee-principal-type ServicePrincipal \
    --scope "/subscriptions/$subscriptionId"
  echo "Role $role_name assigned successfully."
done

# Create federated credential
az ad app federated-credential create --id "$appId" --parameters .credential.json
