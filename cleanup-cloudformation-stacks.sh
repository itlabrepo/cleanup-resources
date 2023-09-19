#!/bin/bash

# Initialize an empty string to store the names of stacks that couldn't be deleted
UNDELETED_STACKS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete CloudFormation stacks
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Get a list of all CloudFormation stacks in the region
    STACKS=$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE UPDATE_ROLLBACK_COMPLETE --region $REGION --query "StackSummaries[].StackName" --output text)
    
    for STACK_NAME in $STACKS; do
        # Disable termination protection for the stack
        aws cloudformation update-termination-protection --stack-name $STACK_NAME --no-enable-termination-protection --region $REGION

        # Attempt to delete the CloudFormation stack
        if aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION ; then
            echo "Successfully initiated deletion of CloudFormation stack: $STACK_NAME in region: $REGION"
        else
            echo "Failed to initiate deletion of CloudFormation stack: $STACK_NAME in region: $REGION"
            UNDELETED_STACKS="$UNDELETED_STACKS $STACK_NAME:$REGION"
        fi
    done
done

# Print the CloudFormation stacks that couldn't be deleted
if [ ! -z "$UNDELETED_STACKS" ]; then
    echo "The following CloudFormation stacks could not be deleted:"
    for STACK in $UNDELETED_STACKS; do
        echo $STACK
    done
else
    echo "Deletion of all CloudFormation stacks in all regions has been initiated. Note that it might take some time for the stacks to be fully deleted."
fi
