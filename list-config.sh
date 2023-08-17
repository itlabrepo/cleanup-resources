#!/bin/bash

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List AWS Config recorders
    RECORDERS=$(aws configservice describe-configuration-recorders --region $REGION --query "ConfigurationRecorders[].name" --output text)
    if [ -n "$RECORDERS" ]; then
        echo "AWS Config recorders in region $REGION:"
        for RECORDER in $RECORDERS; do
            echo $RECORDER
        done
    else
        echo "No AWS Config recorders found in region $REGION."
    fi

    # List AWS Config delivery channels
    CHANNELS=$(aws configservice describe-delivery-channels --region $REGION --query "DeliveryChannels[].name" --output text)
    if [ -n "$CHANNELS" ]; then
        echo "AWS Config delivery channels in region $REGION:"
        for CHANNEL in $CHANNELS; do
            echo $CHANNEL
        done
    else
        echo "No AWS Config delivery channels found in region $REGION."
    fi

    # List AWS Config rules
    RULES=$(aws configservice describe-config-rules --region $REGION --query "ConfigRules[].ConfigRuleName" --output text)
    if [ -n "$RULES" ]; then
        echo "AWS Config rules in region $REGION:"
        for RULE in $RULES; do
            echo $RULE
        done
    else
        echo "No AWS Config rules found in region $REGION."
    fi

    # List AWS Config configuration aggregators
    AGGREGATORS=$(aws configservice describe-configuration-aggregators --region $REGION --query "ConfigurationAggregators[].ConfigurationAggregatorName" --output text)
    if [ -n "$AGGREGATORS" ]; then
        echo "AWS Config configuration aggregators in region $REGION:"
        for AGGREGATOR in $AGGREGATORS; do
            echo $AGGREGATOR
        done
    else
        echo "No AWS Config configuration aggregators found in region $REGION."
    fi

    # List AWS Config conformance packs
    PACKS=$(aws configservice describe-conformance-packs --region $REGION --query "ConformancePackDetails[].ConformancePackName" --output text)
    if [ -n "$PACKS" ]; then
        echo "AWS Config conformance packs in region $REGION:"
        for PACK in $PACKS; do
            echo $PACK
        done
    else
        echo "No AWS Config conformance packs found in region $REGION."
    fi

    # List AWS Config organization conformance packs
    ORG_PACKS=$(aws configservice describe-organization-conformance-packs --region $REGION --query "OrganizationConformancePacks[].OrganizationConformancePackName" --output text)
    if [ -n "$ORG_PACKS" ]; then
        echo "AWS Config organization conformance packs in region $REGION:"
        for ORG_PACK in $ORG_PACKS; do
            echo $ORG_PACK
        done
    else
        echo "No AWS Config organization conformance packs found in region $REGION."
    fi
done
