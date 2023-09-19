#!/bin/bash

# Initialize an empty string to store the names of config rules that couldn't be deleted
UNDELETED_RULES=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete AWS Config custom rules
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Get a list of all AWS Config rules in the region
    RULES=$(aws configservice describe-config-rules --region $REGION --query "ConfigRules[?CreatedBy.AWSManagedRule==\`false\`].ConfigRuleName" --output text)
    
    for RULE_NAME in $RULES; do
        # Attempt to delete the AWS Config rule
        if aws configservice delete-config-rule --config-rule-name $RULE_NAME --region $REGION ; then
            echo "Successfully deleted AWS Config rule: $RULE_NAME in region: $REGION"
        else
            echo "Failed to delete AWS Config rule: $RULE_NAME in region: $REGION"
            UNDELETED_RULES="$UNDELETED_RULES $RULE_NAME:$REGION"
        fi
    done
done

# Print the AWS Config rules that couldn't be deleted
if [ ! -z "$UNDELETED_RULES" ]; then
    echo "The following AWS Config rules could not be deleted:"
    for RULE in $UNDELETED_RULES; do
        echo $RULE
    done
else
    echo "All AWS Config custom rules in all regions were deleted successfully."
fi
