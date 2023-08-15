#!/bin/bash

# Initialize an empty string to store the names of RDS databases that couldn't be deleted
UNDELETED_RDS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List all RDS databases in the current region
    RDS_DBS=$(aws rds describe-db-instances --region $REGION --query "DBInstances[].DBInstanceIdentifier" --output text)

    for DB in $RDS_DBS; do
        echo "Attempting to delete RDS database: $DB in region: $REGION"

        # Try to delete the RDS database (with the --skip-final-snapshot option to avoid creating a final snapshot)
        if aws rds delete-db-instance --db-instance-identifier $DB --skip-final-snapshot --region $REGION ; then
            echo "Successfully deleted RDS database: $DB in region: $REGION"
        else
            echo "Failed to delete RDS database: $DB in region: $REGION"
            UNDELETED_RDS="$UNDELETED_RDS $DB:$REGION"
        fi
    done
done

# Check if there were any RDS databases that couldn't be deleted
if [ -n "$UNDELETED_RDS" ]; then
    echo "The following RDS databases could not be deleted:"
    for DB in $UNDELETED_RDS; do
        echo $DB
    done
else
    echo "All RDS databases deleted successfully."
fi
