#!/bin/bash

# Initialize an empty string to store the names of buckets that couldn't be deleted
UNDELETED_BUCKETS=""

# List all buckets
BUCKETS=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

for BUCKET in $BUCKETS; do
    echo "Attempting to delete bucket: $BUCKET"

    # Empty the bucket
    aws s3 rm s3://$BUCKET/ --recursive

    # Try to delete the bucket
    if aws s3api delete-bucket --bucket $BUCKET ; then
        echo "Successfully deleted bucket: $BUCKET"
    else
        echo "Failed to delete bucket: $BUCKET"
        UNDELETED_BUCKETS="$UNDELETED_BUCKETS $BUCKET"
    fi
done

# Check if there were any buckets that couldn't be deleted
if [ -n "$UNDELETED_BUCKETS" ]; then
    echo "The following buckets could not be deleted:"
    for BUCKET in $UNDELETED_BUCKETS; do
        echo $BUCKET
    done
else
    echo "All buckets deleted successfully."
fi
