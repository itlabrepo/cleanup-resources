#!/bin/bash

# Initialize an empty string to store the names of VPCs that couldn't be deleted
UNDELETED_VPCS=""

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# For each region, list and attempt to delete VPCs
for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # Get a list of all VPCs in the region
    VPCS=$(aws ec2 describe-vpcs --region $REGION --query "Vpcs[].VpcId" --output text)
    
    for VPC_ID in $VPCS; do
        # Delete all subnets associated with the VPC
        SUBNETS=$(aws ec2 describe-subnets --region $REGION --filters Name=vpc-id,Values=$VPC_ID --query "Subnets[].SubnetId" --output text)
        for SUBNET in $SUBNETS; do
            aws ec2 delete-subnet --subnet-id $SUBNET --region $REGION
        done

        # Detach and delete all Internet Gateways associated with the VPC
        IGWS=$(aws ec2 describe-internet-gateways --region $REGION --filters Name=attachment.vpc-id,Values=$VPC_ID --query "InternetGateways[].InternetGatewayId" --output text)
        for IGW in $IGWS; do
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID --region $REGION
            aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION
        done

        # Delete all network ACLs associated with the VPC (excluding the default)
        NACLS=$(aws ec2 describe-network-acls --region $REGION --filters Name=vpc-id,Values=$VPC_ID --query "NetworkAcls[?IsDefault!=`true`].NetworkAclId" --output text)
        for NACL in $NACLS; do
            aws ec2 delete-network-acl --network-acl-id $NACL --region $REGION
        done

        # Delete all security groups associated with the VPC (excluding the default)
        SEC_GROUPS=$(aws ec2 describe-security-groups --region $REGION --filters Name=vpc-id,Values=$VPC_ID --query "SecurityGroups[?GroupName!=`default`].GroupId" --output text)
        for SEC_GROUP in $SEC_GROUPS; do
            # Revoke all inbound and outbound rules
            aws ec2 revoke-security-group-ingress --group-id $SEC_GROUP --protocol all --port all --cidr 0.0.0.0/0 --region $REGION
            aws ec2 revoke-security-group-egress --group-id $SEC_GROUP --protocol all --port all --cidr 0.0.0.0/0 --region $REGION

            # Delete the security group
            aws ec2 delete-security-group --group-id $SEC_GROUP --region $REGION
        done

        # Detach and delete all NAT Gateways associated with the VPC
        NAT_GWS=$(aws ec2 describe-nat-gateways --region $REGION --filter Name=vpc-id,Values=$VPC_ID --query "NatGateways[].NatGatewayId" --output text)
        for NAT_GW in $NAT_GWS; do
            aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW --region $REGION
        done

        # Delete the VPC
        if aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION ; then
            echo "Successfully deleted VPC: $VPC_ID in region: $REGION"
        else
            echo "Failed to delete VPC: $VPC_ID in region: $REGION"
            UNDELETED_VPCS="$UNDELETED_VPCS $VPC_ID:$REGION"
        fi
    done

    # Delete DHCP option sets that are not associated with any VPC
    DHCP_OPTION_SETS=$(aws ec2 describe-dhcp-options --region $REGION --query "DhcpOptions[?not_null(DhcpConfigurations[?Key=='domain-name'])].DhcpOptionsId" --output text)
    for DHCP_OPTION_SET in $DHCP_OPTION_SETS; do
        aws ec2 delete-dhcp-options --dhcp-options-id $DHCP_OPTION_SET --region $REGION
    done
done

# Print the VPCs that couldn't be deleted
if [ ! -z "$UNDELETED_VPCS" ]; then
    echo "The following VPCs could not be deleted:"
    for VPC in $UNDELETED_VPCS; do
        echo $VPC
    done
else
    echo "All VPCs in all regions were deleted successfully."
fi
