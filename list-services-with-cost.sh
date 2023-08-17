#!/bin/bash

# Set the date range for the cost and usage data
START_DATE=$(date -d "1 month ago" +%Y-%m-01)
END_DATE=$(date +%Y-%m-%d)

# Get the cost and usage data for AWS services
COST_DATA=$(aws ce get-cost-and-usage \
    --time-period Start=$START_DATE,End=$END_DATE \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --query "ResultsByTime[0].Groups[?Metrics.UnblendedCost.Amount!='0'].Keys[]" \
    --output text)

# Check if there are any AWS services with resources created
if [ -n "$COST_DATA" ]; then
    echo "AWS services with resources created:"
    echo "$COST_DATA" | tr '\t' '\n'
else
    echo "No AWS services with resources created found."
fi
