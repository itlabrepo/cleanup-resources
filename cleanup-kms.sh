#!/bin/bash

# Initialize an empty string to store the KMS keys that cannot be scheduled for deletion
UNDELETABLE_KEYS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to schedule deletion of KMS customer managed keys
for REGION in $REGIONS; do
    echo "Checking region: $REGION"
    # Get a list of all KMS customer managed keys in the region
    KMS_KEYS=$(aws kms list-keys --region $REGION --query "Keys[].KeyId" --output text)
    
    for KEY_ID in $KMS_KEYS; do
        # Check if the key is customer managed
        KEY_METADATA=$(aws kms describe-key --key-id $KEY_ID --region $REGION)
        KEY_MANAGER=$(echo $KEY_METADATA | jq -r .KeyMetadata.KeyManager)
        
        if [ "$KEY_MANAGER" == "CUSTOMER" ]; then
            # Schedule the key for deletion
            if aws kms schedule-key-deletion --key-id $KEY_ID --pending-window-in-days 7 --region $REGION ; then
                echo "Successfully scheduled KMS key for deletion: $KEY_ID in region: $REGION"
            else
                UNDELETABLE_KEYS="$UNDELETABLE_KEYS $KEY_ID:$REGION"
            fi
        fi
    done
done

# Print the KMS keys that cannot be scheduled for deletion
if [ ! -z "$UNDELETABLE_KEYS" ]; then
    echo "The following KMS keys could not be scheduled for deletion:"
    for KEY in $UNDELETABLE_KEYS; do
        echo $KEY
    done
else
    echo "All KMS customer managed keys in all regions were scheduled for deletion successfully."
fi
