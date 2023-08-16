#!/bin/bash

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Delete AWS Config delivery channels
    CHANNELS=$(aws configservice describe-delivery-channels --region $REGION --query "DeliveryChannels[].name" --output text)
    for CHANNEL in $CHANNELS; do
        aws configservice delete-delivery-channel --delivery-channel-name $CHANNEL --region $REGION
    done

    # Stop AWS Config recorders
    RECORDERS=$(aws configservice describe-configuration-recorders --region $REGION --query "ConfigurationRecorders[].name" --output text)
    for RECORDER in $RECORDERS; do
        aws configservice stop-configuration-recorder --configuration-recorder-name $RECORDER --region $REGION
    done

    # Delete AWS Config recorders
    for RECORDER in $RECORDERS; do
        aws configservice delete-configuration-recorder --configuration-recorder-name $RECORDER --region $REGION
    done

    # Delete AWS Config configuration aggregators
    AGGREGATORS=$(aws configservice describe-configuration-aggregators --region $REGION --query "ConfigurationAggregators[].ConfigurationAggregatorName" --output text)
    for AGGREGATOR in $AGGREGATORS; do
        aws configservice delete-configuration-aggregator --configuration-aggregator-name $AGGREGATOR --region $REGION
    done

    # Delete AWS Config conformance packs
    PACKS=$(aws configservice describe-conformance-packs --region $REGION --query "ConformancePackDetails[].ConformancePackName" --output text)
    for PACK in $PACKS; do
        aws configservice delete-conformance-pack --conformance-pack-name $PACK --region $REGION
    done

    # Delete AWS Config organization conformance packs
    ORG_PACKS=$(aws configservice describe-organization-conformance-packs --region $REGION --query "OrganizationConformancePacks[].OrganizationConformancePackName" --output text)
    for ORG_PACK in $ORG_PACKS; do
        aws configservice delete-organization-conformance-pack --organization-conformance-pack-name $ORG_PACK --region $REGION
    done

    # Delete AWS Config rules
    RULES=$(aws configservice describe-config-rules --region $REGION --query "ConfigRules[].ConfigRuleName" --output text)
    for RULE in $RULES; do
        aws configservice delete-config-rule --config-rule-name $RULE --region $REGION
    done
done

echo "AWS Config settings and data have been cleaned up in all regions."
