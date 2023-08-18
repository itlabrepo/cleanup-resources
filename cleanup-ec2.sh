#!/bin/bash

# Initialize an empty string to store the IDs of resources that couldn't be deleted
UNDELETED_RESOURCES=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Terminate all EC2 instances
    # ... (same as previous script)

    # Delete all volumes
    # ... (same as previous script)

    # Delete all snapshots
    # ... (same as previous script)

    # Release all elastic IPs
    # ... (same as previous script)

    # Delete all NAT gateways
    # ... (same as previous script)

    # Delete all Internet gateways
    IGWS=$(aws ec2 describe-internet-gateways --region $REGION --query "InternetGateways[*].InternetGatewayId" --output text)
    for IGW in $IGWS; do
        # Detach the Internet gateway from the VPC
        VPC=$(aws ec2 describe-internet-gateways --internet-gateway-ids $IGW --region $REGION --query "InternetGateways[*].Attachments[*].VpcId" --output text)
        if [ -n "$VPC" ]; then
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC --region $REGION
        fi

        # Delete the Internet gateway
        if aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION ; then
            echo "Successfully deleted Internet gateway: $IGW in region: $REGION"
        else
            echo "Failed to delete Internet gateway: $IGW in region: $REGION"
            UNDELETED_RESOURCES="$UNDELETED_RESOURCES $IGW:$REGION"
        fi
    done

    # Delete all VPC endpoints
    # ... (same as previous script)
done

# Check if there were any resources that couldn't be deleted
if [ -n "$UNDELETED_RESOURCES" ]; then
    echo "The following resources could not be deleted:"
    for RESOURCE in $UNDELETED_RESOURCES; do
        echo $RESOURCE
    done
else
    echo "All EC2 instances and related resources deleted successfully."
fi
#!/bin/bash

# Initialize an empty string to store the IDs of resources that couldn't be deleted
UNDELETED_RESOURCES=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Terminate all EC2 instances
    # ... (same as previous script)

    # Delete all volumes
    # ... (same as previous script)

    # Delete all snapshots
    # ... (same as previous script)

    # Release all elastic IPs
    # ... (same as previous script)

    # Delete all NAT gateways
    # ... (same as previous script)

    # Delete all Internet gateways
    IGWS=$(aws ec2 describe-internet-gateways --region $REGION --query "InternetGateways[*].InternetGatewayId" --output text)
    for IGW in $IGWS; do
        # Detach the Internet gateway from the VPC
        VPC=$(aws ec2 describe-internet-gateways --internet-gateway-ids $IGW --region $REGION --query "InternetGateways[*].Attachments[*].VpcId" --output text)
        if [ -n "$VPC" ]; then
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC --region $REGION
        fi

        # Delete the Internet gateway
        if aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION ; then
            echo "Successfully deleted Internet gateway: $IGW in region: $REGION"
        else
            echo "Failed to delete Internet gateway: $IGW in region: $REGION"
            UNDELETED_RESOURCES="$UNDELETED_RESOURCES $IGW:$REGION"
        fi
    done

    # Delete all VPC endpoints
    # ... (same as previous script)
done

# Check if there were any resources that couldn't be deleted
if [ -n "$UNDELETED_RESOURCES" ]; then
    echo "The following resources could not be deleted:"
    for RESOURCE in $UNDELETED_RESOURCES; do
        echo $RESOURCE
    done
else
    echo "All EC2 instances and related resources deleted successfully."
fi
