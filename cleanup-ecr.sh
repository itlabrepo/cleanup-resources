#!/bin/bash

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List ECR repositories
    REPOSITORIES=$(aws ecr describe-repositories --region $REGION --query "repositories[].repositoryName" --output text)
    if [ -n "$REPOSITORIES" ]; then
        echo "ECR repositories in region $REGION:"
        for REPO in $REPOSITORIES; do
            echo $REPO
        done
    else
        echo "No ECR repositories found in region $REGION."
    fi

    # Clean up ECR repositories
    for REPO in $REPOSITORIES; do
        # List images in the repository
        IMAGES=$(aws ecr list-images --repository-name $REPO --region $REGION --query "imageIds[].imageDigest" --output text)
        if [ -n "$IMAGES" ]; then
            # Delete images in the repository
            for IMAGE in $IMAGES; do
                aws ecr batch-delete-image --repository-name $REPO --image-ids imageDigest=$IMAGE --region $REGION
            done
        fi

        # Delete the repository
        aws ecr delete-repository --repository-name $REPO --force --region $REGION
    done
done

echo "ECR settings and data have been cleaned up in all regions."
