#!/bin/bash

# Initialize an empty string to store the names of SNS topics that couldn't be deleted
UNDELETED_TOPICS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete SNS resources
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Get a list of all SNS topics in the region
    TOPICS=$(aws sns list-topics --region $REGION --query "Topics[].TopicArn" --output text)
    
    for TOPIC_ARN in $TOPICS; do
        # List and delete all subscriptions associated with the topic
        SUBSCRIPTIONS=$(aws sns list-subscriptions-by-topic --topic-arn $TOPIC_ARN --region $REGION --query "Subscriptions[].SubscriptionArn" --output text)
        for SUBSCRIPTION_ARN in $SUBSCRIPTIONS; do
            aws sns unsubscribe --subscription-arn $SUBSCRIPTION_ARN --region $REGION
        done

        # Delete the SNS topic
        if aws sns delete-topic --topic-arn $TOPIC_ARN --region $REGION ; then
            echo "Successfully deleted SNS topic: $TOPIC_ARN in region: $REGION"
        else
            echo "Failed to delete SNS topic: $TOPIC_ARN in region: $REGION"
            UNDELETED_TOPICS="$UNDELETED_TOPICS $TOPIC_ARN:$REGION"
        fi
    done

    # Delete all platform applications (for mobile notifications)
    PLATFORM_APPLICATIONS=$(aws sns list-platform-applications --region $REGION --query "PlatformApplications[].PlatformApplicationArn" --output text)
    for PLATFORM_APP_ARN in $PLATFORM_APPLICATIONS; do
        aws sns delete-platform-application --platform-application-arn $PLATFORM_APP_ARN --region $REGION
    done
done

# Print the SNS topics that couldn't be deleted
if [ ! -z "$UNDELETED_TOPICS" ]; then
    echo "The following SNS topics could not be deleted:"
    for TOPIC in $UNDELETED_TOPICS; do
        echo $TOPIC
    done
else
    echo "All SNS resources in all regions were deleted successfully."
fi
