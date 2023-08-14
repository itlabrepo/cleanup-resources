#!/bin/bash

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List all AWS Config recorders in the current region
    RECORDERS=$(aws configservice describe-configuration-recorders --region $REGION --query "ConfigurationRecorders[].name" --output text)

    for RECORDER in $RECORDERS; do
        echo "Stopping AWS Config recorder: $RECORDER in region: $REGION"

        # Stop the AWS Config recorder
        aws configservice stop-configuration-recorder --configuration-recorder-name $RECORDER --region $REGION
    done

    # List all AWS Config delivery channels in the current region
    CHANNELS=$(aws configservice describe-delivery-channels --region $REGION --query "DeliveryChannels[].name" --output text)

    for CHANNEL in $CHANNELS; do
        echo "Deleting AWS Config delivery channel: $CHANNEL in region: $REGION"

        # Delete the AWS Config delivery channel
        aws configservice delete-delivery-channel --delivery-channel-name $CHANNEL --region $REGION
    done
done

echo "AWS Config has been disabled in all regions."
