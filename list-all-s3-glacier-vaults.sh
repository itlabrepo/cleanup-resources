#!/bin/bash

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List all Glacier vaults in the current region
    VAULTS=$(aws glacier list-vaults --account-id - --region $REGION --query "VaultList[].VaultName" --output text)

    if [ -n "$VAULTS" ]; then
        echo "Glacier vaults in region $REGION:"
        for VAULT in $VAULTS; do
            echo $VAULT
        done
    else
        echo "No Glacier vaults found in region $REGION."
    fi
done
