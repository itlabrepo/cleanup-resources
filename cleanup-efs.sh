#!/bin/bash

# Initialize an empty string to store the IDs of EFS file systems that couldn't be deleted
UNDELETED_EFS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List all EFS file systems in the current region
    EFS_IDS=$(aws efs describe-file-systems --region $REGION --query "FileSystems[].FileSystemId" --output text)

    for EFS_ID in $EFS_IDS; do
        echo "Attempting to delete EFS: $EFS_ID in region: $REGION"

        # Try to delete the EFS file system
        if aws efs delete-file-system --file-system-id $EFS_ID --region $REGION ; then
            echo "Successfully deleted EFS: $EFS_ID in region: $REGION"
        else
            echo "Failed to delete EFS: $EFS_ID in region: $REGION"
            UNDELETED_EFS="$UNDELETED_EFS $EFS_ID:$REGION"
        fi
    done
done

# Check if there were any EFS file systems that couldn't be deleted
if [ -n "$UNDELETED_EFS" ]; then
    echo "The following EFS file systems could not be deleted:"
    for EFS in $UNDELETED_EFS; do
        echo $EFS
    done
else
    echo "All EFS file systems deleted successfully."
fi
