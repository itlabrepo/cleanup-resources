#!/bin/bash

# Initialize an empty string to store the names of secrets that couldn't be deleted
UNDELETED_SECRETS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List all secrets in the current region
    SECRETS=$(aws secretsmanager list-secrets --region $REGION --query "SecretList[].Name" --output text)

    for SECRET in $SECRETS; do
        echo "Attempting to delete secret: $SECRET in region: $REGION"

        # Try to delete the secret
        if aws secretsmanager delete-secret --secret-id $SECRET --force-delete-without-recovery --region $REGION ; then
            echo "Successfully deleted secret: $SECRET in region: $REGION"
        else
            echo "Failed to delete secret: $SECRET in region: $REGION"
            UNDELETED_SECRETS="$UNDELETED_SECRETS $SECRET:$REGION"
        fi
    done
done

# Check if there were any secrets that couldn't be deleted
if [ -n "$UNDELETED_SECRETS" ]; then
    echo "The following secrets could not be deleted:"
    for SECRET in $UNDELETED_SECRETS; do
        echo $SECRET
    done
else
    echo "All secrets deleted successfully."
fi
