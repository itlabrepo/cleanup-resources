#!/bin/bash

# Initialize an empty string to store the names of Lambda functions that couldn't be deleted
UNDELETED_LAMBDAS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List all Lambda functions in the current region
    LAMBDAS=$(aws lambda list-functions --region $REGION --query "Functions[].FunctionName" --output text)

    for LAMBDA in $LAMBDAS; do
        echo "Attempting to delete Lambda function: $LAMBDA in region: $REGION"

        # Try to delete the Lambda function
        if aws lambda delete-function --function-name $LAMBDA --region $REGION ; then
            echo "Successfully deleted Lambda function: $LAMBDA in region: $REGION"
        else
            echo "Failed to delete Lambda function: $LAMBDA in region: $REGION"
            UNDELETED_LAMBDAS="$UNDELETED_LAMBDAS $LAMBDA:$REGION"
        fi
    done
done

# Check if there were any Lambda functions that couldn't be deleted
if [ -n "$UNDELETED_LAMBDAS" ]; then
    echo "The following Lambda functions could not be deleted:"
    for LAMBDA in $UNDELETED_LAMBDAS; do
        echo $LAMBDA
    done
else
    echo "All Lambda functions deleted successfully."
fi
