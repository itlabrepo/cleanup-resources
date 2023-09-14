#!/bin/bash

# Initialize empty strings to store resources that cannot be deleted
UNDELETABLE_INSTANCES=""
UNDELETABLE_CLUSTERS=""
UNDELETABLE_SNAPSHOTS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete RDS DB instances, clusters, and snapshots
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Delete RDS DB instances
    INSTANCES=$(aws rds describe-db-instances --region $REGION --query "DBInstances[].DBInstanceIdentifier" --output text)
    for INSTANCE_ID in $INSTANCES; do
        # First, modify the instance to disable deletion protection
        aws rds modify-db-instance --db-instance-identifier $INSTANCE_ID --no-deletion-protection --region $REGION
        if aws rds delete-db-instance --db-instance-identifier $INSTANCE_ID --region $REGION --skip-final-snapshot ; then
            echo "Successfully deleted RDS DB instance: $INSTANCE_ID in region: $REGION"
        else
            UNDELETABLE_INSTANCES="$UNDELETABLE_INSTANCES $INSTANCE_ID:$REGION"
        fi
    done

    # Delete RDS DB clusters
    CLUSTERS=$(aws rds describe-db-clusters --region $REGION --query "DBClusters[].DBClusterIdentifier" --output text)
    for CLUSTER_ID in $CLUSTERS; do
        # First, disable deletion protection
        aws rds modify-db-cluster --db-cluster-identifier $CLUSTER_ID --no-deletion-protection --region $REGION
        if aws rds delete-db-cluster --db-cluster-identifier $CLUSTER_ID --region $REGION --skip-final-snapshot ; then
            echo "Successfully deleted RDS DB cluster: $CLUSTER_ID in region: $REGION"
        else
            UNDELETABLE_CLUSTERS="$UNDELETABLE_CLUSTERS $CLUSTER_ID:$REGION"
        fi
    done

    # Delete RDS snapshots
    SNAPSHOTS=$(aws rds describe-db-snapshots --region $REGION --query "DBSnapshots[].DBSnapshotIdentifier" --output text)
    for SNAPSHOT_ID in $SNAPSHOTS; do
        if aws rds delete-db-snapshot --db-snapshot-identifier $SNAPSHOT_ID --region $REGION ; then
            echo "Successfully deleted RDS snapshot: $SNAPSHOT_ID in region: $REGION"
        else
            UNDELETABLE_SNAPSHOTS="$UNDELETABLE_SNAPSHOTS $SNAPSHOT_ID:$REGION"
        fi
    done
done

# Print resources that could not be deleted
if [ ! -z "$UNDELETABLE_INSTANCES" ]; then
    echo "The following RDS DB instances could not be deleted:"
    for INSTANCE in $UNDELETABLE_INSTANCES; do
        echo $INSTANCE
    done
fi

if [ ! -z "$UNDELETABLE_CLUSTERS" ]; then
    echo "The following RDS DB clusters could not be deleted:"
    for CLUSTER in $UNDELETABLE_CLUSTERS; do
        echo $CLUSTER
    done
fi

if [ ! -z "$UNDELETABLE_SNAPSHOTS" ]; then
    echo "The following RDS snapshots could not be deleted:"
    for SNAPSHOT in $UNDELETABLE_SNAPSHOTS; do
        echo $SNAPSHOT
    done
fi
