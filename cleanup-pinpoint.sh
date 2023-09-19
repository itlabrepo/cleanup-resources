#!/bin/bash

# Initialize an empty string to store the Pinpoint applications that cannot be deleted
UNDELETABLE_APPS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete Pinpoint applications
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Get a list of all Pinpoint applications in the region
    APPS=$(aws pinpoint get-apps --region $REGION --query "ApplicationsResponse.Item[].Id" --output text)
    
    for APP_ID in $APPS; do
        # Attempt to delete the Pinpoint application
        if aws pinpoint delete-app --application-id $APP_ID --region $REGION ; then
            echo "Successfully deleted Pinpoint application: $APP_ID in region: $REGION"
        else
            UNDELETABLE_APPS="$UNDELETABLE_APPS $APP_ID:$REGION"
        fi
    done
done

# Print the Pinpoint applications that cannot be deleted
if [ ! -z "$UNDELETABLE_APPS" ]; then
    echo "The following Pinpoint applications could not be deleted:"
    for APP in $UNDELETABLE_APPS; do
        echo $APP
    done
else
    echo "All Pinpoint applications in all regions were deleted successfully."
fi
