#!/bin/bash

# Initialize an empty string to store the names of identity pools that couldn't be deleted
UNDELETED_POOLS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete Cognito identity pools
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Get a list of all Cognito identity pools in the region
    IDENTITY_POOLS=$(aws cognito-identity list-identity-pools --max-results 60 --region $REGION --query "IdentityPools[].IdentityPoolId" --output text)
    
    for IDENTITY_POOL_ID in $IDENTITY_POOLS; do
        # Attempt to delete the Cognito identity pool
        if aws cognito-identity delete-identity-pool --identity-pool-id $IDENTITY_POOL_ID --region $REGION ; then
            echo "Successfully deleted Cognito identity pool: $IDENTITY_POOL_ID in region: $REGION"
        else
            echo "Failed to delete Cognito identity pool: $IDENTITY_POOL_ID in region: $REGION"
            UNDELETED_POOLS="$UNDELETED_POOLS $IDENTITY_POOL_ID:$REGION"
        fi
    done
done

# Print the Cognito identity pools that cannot be deleted
if [ ! -z "$UNDELETED_POOLS" ]; then
    echo "The following Cognito identity pools could not be deleted:"
    for POOL in $UNDELETED_POOLS; do
        echo $POOL
    done
else
    echo "All Cognito identity pools in all regions were deleted successfully."
fi
