#!/bin/bash

# Initialize an empty string to store the names of resources that couldn't be deleted
UNDELETED_RESOURCES=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete Systems Manager resources
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Delete all parameters from the Parameter Store
    PARAMETERS=$(aws ssm describe-parameters --region $REGION --query "Parameters[].Name" --output text)
    for PARAM in $PARAMETERS; do
        if aws ssm delete-parameter --name $PARAM --region $REGION ; then
            echo "Successfully deleted parameter: $PARAM in region: $REGION"
        else
            echo "Failed to delete parameter: $PARAM in region: $REGION"
            UNDELETED_RESOURCES="$UNDELETED_RESOURCES Parameter:$PARAM:$REGION"
        fi
    done

    # Delete all managed instances
    INSTANCES=$(aws ssm describe-instance-information --region $REGION --query "InstanceInformationList[].InstanceId" --output text)
    for INSTANCE in $INSTANCES; do
        if aws ssm deregister-managed-instance --instance-id $INSTANCE --region $REGION ; then
            echo "Successfully deregistered managed instance: $INSTANCE in region: $REGION"
        else
            echo "Failed to deregister managed instance: $INSTANCE in region: $REGION"
            UNDELETED_RESOURCES="$UNDELETED_RESOURCES ManagedInstance:$INSTANCE:$REGION"
        fi
    done

    # Delete all maintenance windows
    WINDOWS=$(aws ssm describe-maintenance-windows --region $REGION --query "WindowIdentities[].WindowId" --output text)
    for WINDOW in $WINDOWS; do
        if aws ssm delete-maintenance-window --window-id $WINDOW --region $REGION ; then
            echo "Successfully deleted maintenance window: $WINDOW in region: $REGION"
        else
            echo "Failed to delete maintenance window: $WINDOW in region: $REGION"
            UNDELETED_RESOURCES="$UNDELETED_RESOURCES MaintenanceWindow:$WINDOW:$REGION"
        fi
    done

    # Delete all patch baselines
    BASELINES=$(aws ssm describe-patch-baselines --region $REGION --query "BaselineIdentities[].BaselineId" --output text)
    for BASELINE in $BASELINES; do
        if aws ssm delete-patch-baseline --baseline-id $BASELINE --region $REGION ; then
            echo "Successfully deleted patch baseline: $BASELINE in region: $REGION"
        else
            echo "Failed to delete patch baseline: $BASELINE in region: $REGION"
            UNDELETED_RESOURCES="$UNDELETED_RESOURCES PatchBaseline:$BASELINE:$REGION"
        fi
    done

    # Delete all activations
    ACTIVATIONS=$(aws ssm describe-activations --region $REGION --query "ActivationList[].ActivationId" --output text)
    for ACTIVATION in $ACTIVATIONS; do
        if aws ssm delete-activation --activation-id $ACTIVATION --region $REGION ; then
            echo "Successfully deleted activation: $ACTIVATION in region: $REGION"
        else
            echo "Failed to delete activation: $ACTIVATION in region: $REGION"
            UNDELETED_RESOURCES="$UNDELETED_RESOURCES Activation:$ACTIVATION:$REGION"
        fi
    done
done

# Print the Systems Manager resources that couldn't be deleted
if [ ! -z "$UNDELETED_RESOURCES" ]; then
    echo "The following Systems Manager resources could not be deleted:"
    for RESOURCE in $UNDELETED_RESOURCES; do
        echo $RESOURCE
    done
else
    echo "All Systems Manager resources in all regions were deleted successfully."
fi
