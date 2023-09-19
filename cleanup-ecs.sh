#!/bin/bash

# Initialize an empty string to store the names of ECS clusters that couldn't be deleted
UNDELETED_CLUSTERS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete ECS resources
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Get a list of all ECS clusters in the region
    CLUSTERS=$(aws ecs list-clusters --region $REGION --query "clusterArns[]" --output text)
    
    for CLUSTER_ARN in $CLUSTERS; do
        # List and stop all tasks in the cluster
        TASKS=$(aws ecs list-tasks --cluster $CLUSTER_ARN --region $REGION --query "taskArns[]" --output text)
        for TASK_ARN in $TASKS; do
            aws ecs stop-task --cluster $CLUSTER_ARN --task $TASK_ARN --region $REGION
        done

        # List and delete all services in the cluster
        SERVICES=$(aws ecs list-services --cluster $CLUSTER_ARN --region $REGION --query "serviceArns[]" --output text)
        for SERVICE_ARN in $SERVICES; do
            aws ecs delete-service --cluster $CLUSTER_ARN --service $SERVICE_ARN --force --region $REGION
        done

        # Delete the ECS cluster
        if aws ecs delete-cluster --cluster $CLUSTER_ARN --region $REGION ; then
            echo "Successfully deleted ECS cluster: $CLUSTER_ARN in region: $REGION"
        else
            echo "Failed to delete ECS cluster: $CLUSTER_ARN in region: $REGION"
            UNDELETED_CLUSTERS="$UNDELETED_CLUSTERS $CLUSTER_ARN:$REGION"
        fi
    done

    # Delete all task definitions
    TASK_DEFINITIONS=$(aws ecs list-task-definitions --region $REGION --query "taskDefinitionArns[]" --output text)
    for TASK_DEFINITION_ARN in $TASK_DEFINITIONS; do
        aws ecs deregister-task-definition --task-definition $TASK_DEFINITION_ARN --region $REGION --query "taskDefinition.taskDefinitionArn" --output text
    done
done

# Print the ECS clusters that couldn't be deleted
if [ ! -z "$UNDELETED_CLUSTERS" ]; then
    echo "The following ECS clusters could not be deleted:"
    for CLUSTER in $UNDELETED_CLUSTERS; do
        echo $CLUSTER
    done
else
    echo "All ECS resources in all regions were deleted successfully."
fi
