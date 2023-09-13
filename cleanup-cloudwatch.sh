#!/bin/bash

# Initialize empty strings to store resources that cannot be deleted
UNDELETABLE_ALARMS=""
UNDELETABLE_DASHBOARDS=""
UNDELETABLE_METRIC_FILTERS=""
UNDELETABLE_LOG_GROUPS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete CloudWatch resources
for REGION in $REGIONS; do
    echo "Checking region: $REGION"
    # Delete CloudWatch Alarms
    ALARMS=$(aws cloudwatch describe-alarms --region $REGION --query "MetricAlarms[].AlarmName" --output text)
    for ALARM in $ALARMS; do
        if aws cloudwatch delete-alarms --alarm-names $ALARM --region $REGION ; then
            echo "Successfully deleted CloudWatch alarm: $ALARM in region: $REGION"
        else
            UNDELETABLE_ALARMS="$UNDELETABLE_ALARMS $ALARM:$REGION"
        fi
    done

    # Delete CloudWatch Dashboards
    DASHBOARDS=$(aws cloudwatch list-dashboards --region $REGION --query "DashboardEntries[].DashboardName" --output text)
    for DASHBOARD in $DASHBOARDS; do
        if aws cloudwatch delete-dashboards --dashboard-names $DASHBOARD --region $REGION ; then
            echo "Successfully deleted CloudWatch dashboard: $DASHBOARD in region: $REGION"
        else
            UNDELETABLE_DASHBOARDS="$UNDELETABLE_DASHBOARDS $DASHBOARD:$REGION"
        fi
    done

    # Delete CloudWatch Log Groups
    LOG_GROUPS=$(aws logs describe-log-groups --region $REGION --query "logGroups[].logGroupName" --output text)
    for LOG_GROUP in $LOG_GROUPS; do
        if aws logs delete-log-group --log-group-name $LOG_GROUP --region $REGION ; then
            echo "Successfully deleted CloudWatch log group: $LOG_GROUP in region: $REGION"
        else
            UNDELETABLE_LOG_GROUPS="$UNDELETABLE_LOG_GROUPS $LOG_GROUP:$REGION"
        fi
    done
done

# Print resources that couldn't be deleted
if [ ! -z "$UNDELETABLE_ALARMS" ]; then
    echo "The following CloudWatch alarms could not be deleted:"
    for ALARM in $UNDELETABLE_ALARMS; do
        echo $ALARM
    done
fi

if [ ! -z "$UNDELETABLE_DASHBOARDS" ]; then
    echo "The following CloudWatch dashboards could not be deleted:"
    for DASHBOARD in $UNDELETABLE_DASHBOARDS; do
        echo $DASHBOARD
    done
fi

if [ ! -z "$UNDELETABLE_LOG_GROUPS" ]; then
    echo "The following CloudWatch log groups could not be deleted:"
    for LOG_GROUP in $UNDELETABLE_LOG_GROUPS; do
        echo $LOG_GROUP
    done
else
    echo "All CloudWatch settings in all regions were deleted successfully."
fi
