#!/bin/bash

# 変数の定義
RG_NAME=rg-terraform-dev
CAE_NAME=cae-app-terraform-dev

# Daprコンポーネントの登録
az containerapp env dapr-component set -g $RG_NAME -n $CAE_NAME --dapr-component-name product-store --yaml cosmosdb.azure.yml
az containerapp env dapr-component set -g $RG_NAME -n $CAE_NAME --dapr-component-name secret-store --yaml secretstore.azure.yaml
