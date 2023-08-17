#!/bin/bash

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Check if Security Hub is enabled in the region
    STATUS=$(aws securityhub get-enabled-standards --region $REGION --query "StandardsSubscriptions[].StandardsSubscriptionArn" --output text)
    if [ -n "$STATUS" ]; then
        echo "Security Hub is enabled in region $REGION."

        # List and disable standards
        STANDARDS=$(aws securityhub get-enabled-standards --region $REGION --query "StandardsSubscriptions[].StandardsSubscriptionArn" --output text)
        for STANDARD in $STANDARDS; do
            aws securityhub disable-security-hub --region $REGION
        done

        # List and delete insight results
        INSIGHTS=$(aws securityhub get-insights --region $REGION --query "Insights[].InsightArn" --output text)
        for INSIGHT in $INSIGHTS; do
            aws securityhub delete-insight --insight-arn $INSIGHT --region $REGION
        done

        # List and delete findings
        FINDINGS=$(aws securityhub get-findings --region $REGION --query "Findings[].Arn" --output text)
        for FINDING in $FINDINGS; do
            aws securityhub.delete-findings --finding-arns $FINDING --region $REGION
        done

        # List and delete actions
        ACTIONS=$(aws securityhub get-actions --region $REGION --query "Actions[].ActionArn" --output text)
        for ACTION in $ACTIONS; do
            aws securityhub delete-action --action-arn $ACTION --region $REGION
        done

        # Disable Security Hub
        aws securityhub disable-security-hub --region $REGION
    else
        echo "Security Hub is not enabled in region $REGION."
    fi
done

echo "Security Hub settings and data have been cleaned up in all regions."
