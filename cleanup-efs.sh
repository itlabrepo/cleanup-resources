#!/bin/bash

# Initialize an empty string to store the IDs of EFS file systems that couldn't be deleted
UNDELETED_EFS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"
    # Get a list of all EFS IDs in the region
    EFS_IDS=$(aws efs describe-file-systems --region $REGION --query "FileSystems[].FileSystemId" --output text)

    # Initialize an empty string to store the EFS IDs that cannot be deleted
    UNDELETABLE_EFS=""

    # For each EFS, delete its mount targets and then try to delete the EFS
    for EFS_ID in $EFS_IDS; do
        # Get the mount targets for the EFS
        MOUNT_TARGETS=$(aws efs describe-mount-targets --file-system-id $EFS_ID --region $REGION --query "MountTargets[].MountTargetId" --output text)
        
        # Delete each mount target
        for MT in $MOUNT_TARGETS; do
            aws efs delete-mount-target --mount-target-id $MT --region $REGION
            echo "Deleted mount target: $MT for EFS: $EFS_ID"
        done
        
        # Wait for a few seconds to ensure all mount targets are deleted
        sleep 20
        
        # Try to delete the EFS
        if aws efs delete-file-system --file-system-id $EFS_ID --region $REGION ; then
            echo "Successfully deleted EFS: $EFS_ID"
        else
            UNDELETABLE_EFS="$UNDELETABLE_EFS $EFS_ID"
        fi
    done
done

# Print the EFS IDs that cannot be deleted
if [ ! -z "$UNDELETABLE_EFS" ]; then
    echo "The following EFS instances could not be deleted:"
    for EFS in $UNDELETABLE_EFS; do
        echo $EFS
    done
else
    echo "All EFS instances in the region were deleted successfully."
fi

