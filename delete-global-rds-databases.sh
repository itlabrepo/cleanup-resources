#!/bin/bash

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List all RDS global databases in the current region
    GLOBAL_CLUSTERS=$(aws rds describe-global-clusters --region $REGION --query "GlobalClusters[?DeletionProtection=='false'].GlobalClusterIdentifier" --output text)

    for GLOBAL_CLUSTER in $GLOBAL_CLUSTERS; do
        echo "Attempting to delete RDS global database: $GLOBAL_CLUSTER in region: $REGION"

        # Turn off deletion protection for the global database
        aws rds modify-global-cluster --global-cluster-identifier $GLOBAL_CLUSTER --no-deletion-protection --region $REGION

        # Delete the global database
        aws rds delete-global-cluster --global-cluster-identifier $GLOBAL_CLUSTER --region $REGION

        echo "Deleted RDS global database: $GLOBAL_CLUSTER in region: $REGION"
    done
done

echo "All RDS global databases have been deleted."
