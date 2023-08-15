#!/bin/bash

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List all secrets in the current region
    SECRETS=$(aws secretsmanager list-secrets --region $REGION --query "SecretList[].Name" --output text)

    if [ -n "$SECRETS" ]; then
        echo "Secrets in region $REGION:"
        for SECRET in $SECRETS; do
            echo $SECRET
        done
    else
        echo "No secrets found in region $REGION."
    fi
done
