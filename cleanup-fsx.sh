#!/bin/bash

# Initialize an empty string to store the names of FSx resources that couldn't be deleted
UNDELETED_FSX_RESOURCES=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete FSx resources
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Delete all FSx file systems
    FSX_FILE_SYSTEMS=$(aws fsx describe-file-systems --region $REGION --query "FileSystems[].FileSystemId" --output text)
    for FS in $FSX_FILE_SYSTEMS; do
        if aws fsx delete-file-system --file-system-id $FS --region $REGION ; then
            echo "Successfully deleted FSx file system: $FS in region: $REGION"
        else
            echo "Failed to delete FSx file system: $FS in region: $REGION"
            UNDELETED_FSX_RESOURCES="$UNDELETED_FSX_RESOURCES FileSystem:$FS:$REGION"
        fi
    done

    # Delete all FSx backups
    FSX_BACKUPS=$(aws fsx describe-backups --region $REGION --query "Backups[].BackupId" --output text)
    for BACKUP in $FSX_BACKUPS; do
        if aws fsx delete-backup --backup-id $BACKUP --region $REGION ; then
            echo "Successfully deleted FSx backup: $BACKUP in region: $REGION"
        else
            echo "Failed to delete FSx backup: $BACKUP in region: $REGION"
            UNDELETED_FSX_RESOURCES="$UNDELETED_FSX_RESOURCES Backup:$BACKUP:$REGION"
        fi
    done

  
done

# Print the FSx resources that couldn't be deleted
if [ ! -z "$UNDELETED_FSX_RESOURCES" ]; then
    echo "The following FSx resources could not be deleted:"
    for RESOURCE in $UNDELETED_FSX_RESOURCES; do
        echo $RESOURCE
    done
else
    echo "All FSx resources in all regions were deleted successfully."
fi
