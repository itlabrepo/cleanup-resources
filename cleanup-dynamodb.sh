#!/bin/bash

# Initialize empty strings to store the DynamoDB tables and backups that cannot be deleted
UNDELETABLE_TABLES=""
UNDELETABLE_BACKUPS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete DynamoDB tables and backups
for REGION in $REGIONS; do
    echo "Checking region: $REGION"
    # Get a list of all DynamoDB tables in the region
    DYNAMO_TABLES=$(aws dynamodb list-tables --region $REGION --query "TableNames[]" --output text)
    
    # For each DynamoDB table, attempt to delete it
    for TABLE in $DYNAMO_TABLES; do
        if aws dynamodb delete-table --table-name $TABLE --region $REGION --query "TableDescription.TableArn" --output text; then
            echo "Successfully deleted DynamoDB table: $TABLE in region: $REGION"
        else
            UNDELETABLE_TABLES="$UNDELETABLE_TABLES $TABLE:$REGION"
        fi
    done

    # Get a list of all DynamoDB backups in the region
    DYNAMO_BACKUPS=$(aws dynamodb list-backups --region $REGION --query "BackupSummaries[].BackupArn" --output text)
    
    # For each DynamoDB backup, attempt to delete it
    for BACKUP in $DYNAMO_BACKUPS; do
        if aws dynamodb delete-backup --backup-arn $BACKUP --region $REGION ; then
            echo "Successfully deleted DynamoDB backup: $BACKUP in region: $REGION"
        else
            UNDELETABLE_BACKUPS="$UNDELETABLE_BACKUPS $BACKUP:$REGION"
        fi
    done
done

# Print the DynamoDB tables and backups that cannot be deleted
if [ ! -z "$UNDELETABLE_TABLES" ]; then
    echo "The following DynamoDB tables could not be deleted:"
    for TABLE in $UNDELETABLE_TABLES; do
        echo $TABLE
    done
fi

if [ ! -z "$UNDELETABLE_BACKUPS" ]; then
    echo "The following DynamoDB backups could not be deleted:"
    for BACKUP in $UNDELETABLE_BACKUPS; do
        echo $BACKUP
    done
else
    echo "All DynamoDB tables and backups in all regions were deleted successfully."
fi
