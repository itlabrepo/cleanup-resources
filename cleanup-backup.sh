#!/bin/bash

# Get a list of all AWS regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for REGION in $REGIONS; do
    echo "Checking region: $REGION"

    # List and delete backup plans
    PLANS=$(aws backup list-backup-plans --region $REGION --query "BackupPlansList[].BackupPlanId" --output text)
    if [ -n "$PLANS" ]; then
        echo "Backup plans in region $REGION:"
        for PLAN in $PLANS; do
            echo $PLAN
            aws backup delete-backup-plan --backup-plan-id $PLAN --region $REGION
        done
    else
        echo "No backup plans found in region $REGION."
    fi

    # List backup vaults
    VAULTS=$(aws backup list-backup-vaults --region $REGION --query "BackupVaultList[].BackupVaultName" --output text)
    if [ -n "$VAULTS" ]; then
        echo "Backup vaults in region $REGION:"
        for VAULT in $VAULTS; do
            echo $VAULT

            # List and delete recovery points
            RECOVERY_POINTS=$(aws backup list-recovery-points-by-backup-vault --backup-vault-name $VAULT --region $REGION --query "RecoveryPoints[].RecoveryPointArn" --output text)
            if [ -n "$RECOVERY_POINTS" ]; then
                echo "Recovery points in backup vault $VAULT:"
                for RECOVERY_POINT in $RECOVERY_POINTS; do
                    echo $RECOVERY_POINT
                    aws backup delete-recovery-point --backup-vault-name $VAULT --recovery-point-arn $RECOVERY_POINT --region $REGION
                done
            else
                echo "No recovery points found in backup vault $VAULT."
            fi

            # Delete the backup vault
            aws backup delete-backup-vault --backup-vault-name $VAULT --region $REGION
        done
    else
        echo "No backup vaults found in region $REGION."
    fi
done

echo "AWS Backup resources and data have been cleaned up in all regions."
