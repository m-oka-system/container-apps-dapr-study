#!/bin/bash

ACR_NAME=""
IMAGE_NAME="api"
TAG="v1"

az acr build --registry "$ACR_NAME" --image "$IMAGE_NAME:$TAG" --file Dockerfile .
