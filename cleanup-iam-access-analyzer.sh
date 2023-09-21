#!/bin/bash

# Initialize an empty string to store the names of analyzers that couldn't be deleted
UNDELETED_ANALYZERS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete IAM Access Analyzers
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Get a list of all IAM Access Analyzers in the region
    ANALYZERS=$(aws accessanalyzer list-analyzers --region $REGION --query "analyzers[].arn" --output text)
    
    for ANALYZER_ARN in $ANALYZERS; do
        # Delete the IAM Access Analyzer
        if aws accessanalyzer delete-analyzer --analyzer-name $(basename $ANALYZER_ARN) --region $REGION ; then
            echo "Successfully deleted IAM Access Analyzer: $ANALYZER_ARN in region: $REGION"
        else
            echo "Failed to delete IAM Access Analyzer: $ANALYZER_ARN in region: $REGION"
            UNDELETED_ANALYZERS="$UNDELETED_ANALYZERS $ANALYZER_ARN:$REGION"
        fi
    done
done

# Print the IAM Access Analyzers that couldn't be deleted
if [ ! -z "$UNDELETED_ANALYZERS" ]; then
    echo "The following IAM Access Analyzers could not be deleted:"
    for ANALYZER in $UNDELETED_ANALYZERS; do
        echo $ANALYZER
    done
else
    echo "All IAM Access Analyzers in all regions were deleted successfully."
fi
