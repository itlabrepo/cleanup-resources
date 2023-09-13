#!/bin/bash

# Initialize an empty string to store the EKS clusters that cannot be deleted
UNDELETABLE_EKS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete EKS clusters
for REGION in $REGIONS; do
    echo "Checking region: $REGION"
    # Get a list of all EKS clusters in the region
    EKS_CLUSTERS=$(aws eks list-clusters --region $REGION --query "clusters" --output text)
    
    # For each EKS cluster, attempt to delete it
    for EKS_CLUSTER in $EKS_CLUSTERS; do
        if aws eks delete-cluster --name $EKS_CLUSTER --region $REGION ; then
            echo "Successfully deleted EKS cluster: $EKS_CLUSTER in region: $REGION"
        else
            UNDELETABLE_EKS="$UNDELETABLE_EKS $EKS_CLUSTER:$REGION"
        fi
    done
done

# Print the EKS clusters that cannot be deleted
if [ ! -z "$UNDELETABLE_EKS" ]; then
    echo "The following EKS clusters could not be deleted:"
    for EKS in $UNDELETABLE_EKS; do
        echo $EKS
    done
else
    echo "All EKS clusters in all regions were deleted successfully."
fi
