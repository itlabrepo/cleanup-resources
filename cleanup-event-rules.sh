#!/bin/bash

# Initialize an empty string to store the names of event rules that couldn't be deleted
UNDELETED_RULES=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete CloudWatch Events rules
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Get a list of all CloudWatch Events rules in the region
    RULES=$(aws events list-rules --region $REGION --query "Rules[].Name" --output text)
    
    for RULE in $RULES; do
        # List and remove all targets associated with the rule
        TARGETS=$(aws events list-targets-by-rule --rule $RULE --region $REGION --query "Targets[].Id" --output text)
        if [ ! -z "$TARGETS" ]; then
            aws events remove-targets --rule $RULE --ids $TARGETS --region $REGION
        fi

        # Delete the CloudWatch Events rule
        if aws events delete-rule --name $RULE --region $REGION ; then
            echo "Successfully deleted CloudWatch Events rule: $RULE in region: $REGION"
        else
            echo "Failed to delete CloudWatch Events rule: $RULE in region: $REGION"
            UNDELETED_RULES="$UNDELETED_RULES $RULE:$REGION"
        fi
    done
done

# Print the CloudWatch Events rules that couldn't be deleted
if [ ! -z "$UNDELETED_RULES" ]; then
    echo "The following CloudWatch Events rules could not be deleted:"
    for RULE in $UNDELETED_RULES; do
        echo $RULE
    done
else
    echo "All CloudWatch Events rules in all regions were deleted successfully."
fi
