#!/bin/bash

# Initialize an empty string to store the VPC endpoints that cannot be deleted
UNDELETABLE_ENDPOINTS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete VPC endpoints
for REGION in $REGIONS; do
    echo "Checking region: $REGION"
    # Get a list of all VPC endpoints in the region
    ENDPOINTS=$(aws ec2 describe-vpc-endpoints --region $REGION --query "VpcEndpoints[].VpcEndpointId" --output text)
    
    for ENDPOINT_ID in $ENDPOINTS; do
        # Attempt to delete the VPC endpoint
        if aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $ENDPOINT_ID --region $REGION ; then
            echo "Successfully deleted VPC endpoint: $ENDPOINT_ID in region: $REGION"
        else
            UNDELETABLE_ENDPOINTS="$UNDELETABLE_ENDPOINTS $ENDPOINT_ID:$REGION"
        fi
    done
done

# Print the VPC endpoints that cannot be deleted
if [ ! -z "$UNDELETABLE_ENDPOINTS" ]; then
    echo "The following VPC endpoints could not be deleted:"
    for ENDPOINT in $UNDELETABLE_ENDPOINTS; do
        echo $ENDPOINT
    done
else
    echo "All VPC endpoints in all regions were deleted successfully."
fi
