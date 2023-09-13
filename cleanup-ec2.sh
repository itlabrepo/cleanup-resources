#!/bin/bash

# Initialize an empty string to store the IDs of resources that couldn't be deleted
UNDELETED_RESOURCES=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    VPCS=$(aws ec2 describe-vpcs --region $REGION --query "Vpcs[].VpcId" --output text)
    
    for VPC in $VPCS; do
        # Before detaching the Internet gateway:

        # 1. Disassociate and delete all Elastic IP addresses
        EIPS=$(aws ec2 describe-addresses --region $REGION --query "Addresses[].AssociationId" --output text)
        for EIP in $EIPS; do
            aws ec2 disassociate-address --association-id $EIP --region $REGION
            echo "Disassociated Elastic IP: $EIP in region: $REGION"
        done

        # 2. Terminate all EC2 instances
        INSTANCES=$(aws ec2 describe-instances --filters Name=vpc-id,Values=$VPC --region $REGION --query "Reservations[].Instances[].InstanceId" --output text)
        for INSTANCE in $INSTANCES; do
            aws ec2 terminate-instances --instance-ids $INSTANCE --region $REGION
            echo "Terminated EC2 instance: $INSTANCE in region: $REGION"
        done

        # 3. Delete all NAT Gateways
        NAT_GWS=$(aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$VPC --region $REGION --query "NatGateways[?State!='deleted'].NatGatewayId" --output text)
        for NAT_GW in $NAT_GWS; do
            aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW --region $REGION
            echo "Deleted NAT gateway: $NAT_GW in region: $REGION"
        done

        # 4. Delete all Elastic Load Balancers (both Classic and Application Load Balancers)
        # For Classic Load Balancers
        CLBS=$(aws elb describe-load-balancers --region $REGION --query "LoadBalancerDescriptions[?VPCId=='$VPC'].LoadBalancerName" --output text)
        for CLB in $CLBS; do
            aws elb delete-load-balancer --load-balancer-name $CLB --region $REGION
            echo "Deleted Classic Load Balancer: $CLB in region: $REGION"
        done

        # For Application and Network Load Balancers
        ALBS=$(aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?VpcId=='$VPC'].LoadBalancerArn" --output text)
        for ALB in $ALBS; do
            aws elbv2 delete-load-balancer --load-balancer-arn $ALB --region $REGION
            echo "Deleted Application/Network Load Balancer: $ALB in region: $REGION"
        done

        

        # 6. Delete all route tables associated with the VPC (except the main one)
        RTS=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC --region $REGION --query "RouteTables[?Associations[?Main==false]].RouteTableId" --output text)
        for RT in $RTS; do
            aws ec2 delete-route-table --route-table-id $RT --region $REGION
            echo "Deleted route table: $RT in region: $REGION"
        done


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
        # Get a list of all VPC endpoint IDs in the specified region
        ENDPOINT_IDS=$(aws ec2 describe-vpc-endpoints --region $REGION --query "VpcEndpoints[].VpcEndpointId" --output text)

        # Iterate over each endpoint ID and delete it
        for ENDPOINT_ID in $ENDPOINT_IDS; do
            aws ec2 delete-vpc-endpoints --region $REGION --vpc-endpoint-ids $ENDPOINT_ID
            echo "Deleted VPC endpoint: $ENDPOINT_ID in region: $REGION"
        done

    done

    # Delete all subnets
    SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC --region $REGION --query "Subnets[].SubnetId" --output text)
    for SUBNET in $SUBNETS; do
        aws ec2 delete-subnet --subnet-id $SUBNET --region $REGION
        echo "Deleted subnet: $SUBNET in region: $REGION"
    done


    # Delete all volumes
    VOLUMES=$(aws ec2 describe-volumes --region $REGION --query "Volumes[?State!='deleted'].VolumeId" --output text)
    for VOLUME in $VOLUMES; do
        aws ec2 delete-volume --volume-id $VOLUME --region $REGION
        echo "Deleted volume: $VOLUME in region: $REGION"
    done

    # Delete all snapshots
    SNAPSHOTS=$(aws ec2 describe-snapshots --owner-ids $(aws sts get-caller-identity --query "Account" --output text) --region $REGION --query "Snapshots[?State!='completed'].SnapshotId" --output text)
    for SNAPSHOT in $SNAPSHOTS; do
        aws ec2 delete-snapshot --snapshot-id $SNAPSHOT --region $REGION
        echo "Deleted snapshot: $SNAPSHOT in region: $REGION"
    done

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

