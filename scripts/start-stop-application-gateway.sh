#!/bin/bash

# 変数の定義
RG_NAME=rg-studyca
AGW_NAME=agw-studyca

# Application Gatewayの起動
az network application-gateway start --resource-group $RG_NAME --name $AGW_NAME

# Application Gatewayの停止
az network application-gateway stop --resource-group $RG_NAME --name $AGW_NAME
