#!/bin/bash

# Initialize empty strings to store resources that cannot be deleted
UNDELETABLE_INSTANCES=""
UNDELETABLE_CLUSTERS=""
UNDELETABLE_DB_SNAPSHOTS=""
UNDELETABLE_CLUSTER_SNAPSHOTS=""

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

    # Delete RDS DB snapshots
    DB_SNAPSHOTS=$(aws rds describe-db-snapshots --region $REGION --query "DBSnapshots[].DBSnapshotIdentifier" --output text)
    for SNAPSHOT_ID in $DB_SNAPSHOTS; do
        if aws rds delete-db-snapshot --db-snapshot-identifier $SNAPSHOT_ID --region $REGION --query "DBSnapshot.DBSnapshotIdentifier" --output text; then
            echo "Successfully deleted RDS DB snapshot: $SNAPSHOT_ID in region: $REGION"
        else
            UNDELETABLE_DB_SNAPSHOTS="$UNDELETABLE_DB_SNAPSHOTS $SNAPSHOT_ID:$REGION"
        fi
    done

    # Delete RDS cluster snapshots
    CLUSTER_SNAPSHOTS=$(aws rds describe-db-cluster-snapshots --region $REGION --query "DBClusterSnapshots[].DBClusterSnapshotIdentifier" --output text)
    for CLUSTER_SNAPSHOT_ID in $CLUSTER_SNAPSHOTS; do
        if aws rds delete-db-cluster-snapshot --db-cluster-snapshot-identifier $CLUSTER_SNAPSHOT_ID --region $REGION --query "DBClusterSnapshot.DBClusterSnapshotIdentifier" --output text; then
            echo "Successfully deleted RDS cluster snapshot: $CLUSTER_SNAPSHOT_ID in region: $REGION"
        else
            UNDELETABLE_CLUSTER_SNAPSHOTS="$UNDELETABLE_CLUSTER_SNAPSHOTS $CLUSTER_SNAPSHOT_ID:$REGION"
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

if [ ! -z "$UNDELETABLE_DB_SNAPSHOTS" ]; then
    echo "The following RDS DB snapshots could not be deleted:"
    for SNAPSHOT in $UNDELETABLE_DB_SNAPSHOTS; do
        echo $SNAPSHOT
    done
fi

if [ ! -z "$UNDELETABLE_CLUSTER_SNAPSHOTS" ]; then
    echo "The following RDS cluster snapshots could not be deleted:"
    for CLUSTER_SNAPSHOT in $UNDELETABLE_CLUSTER_SNAPSHOTS; do
        echo $CLUSTER_SNAPSHOT
    done
fi
