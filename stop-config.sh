#!/bin/bash

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List all AWS Config rules in the current region
    RULES=$(aws configservice describe-config-rules --region $REGION --query "ConfigRules[].ConfigRuleName" --output text)

    for RULE in $RULES; do
        # Check if the rule is a service-linked rule
        IS_SERVICE_LINKED=$(aws configservice describe-config-rules --config-rule-names $RULE --region $REGION --query "ConfigRules[?Source.Owner=='AWS'].ConfigRuleName" --output text)

        # Skip service-linked rules
        if [ -n "$IS_SERVICE_LINKED" ]; then
            echo "Skipping service-linked rule: $RULE in region: $REGION"
            continue
        fi

        # Delete the rule
        echo "Deleting rule: $RULE in region: $REGION"
        aws configservice delete-config-rule --config-rule-name $RULE --region $REGION
    done

    # List all AWS Config recorders in the current region
    RECORDERS=$(aws configservice describe-configuration-recorders --region $REGION --query "ConfigurationRecorders[].name" --output text)

    for RECORDER in $RECORDERS; do
        # Stop the recorder
        echo "Stopping recorder: $RECORDER in region: $REGION"
        aws configservice stop-configuration-recorder --configuration-recorder-name $RECORDER --region $REGION

        # Delete the recorder
        echo "Deleting recorder: $RECORDER in region: $REGION"
        aws configservice delete-configuration-recorder --configuration-recorder-name $RECORDER --region $REGION
    done

    # List all AWS Config delivery channels in the current region
    CHANNELS=$(aws configservice describe-delivery-channels --region $REGION --query "DeliveryChannels[].name" --output text)

    for CHANNEL in $CHANNELS; do
        # Delete the delivery channel
        echo "Deleting delivery channel: $CHANNEL in region: $REGION"
        aws configservice delete-delivery-channel --delivery-channel-name $CHANNEL --region $REGION
    done
done

echo "AWS Config settings and data have been cleaned up in all regions."
