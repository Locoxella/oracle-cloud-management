#!/bin/bash

# Configuration
COMPARTMENT_ID="ocid1.tenancy.oc1..aaaaaaaacdo7v2uzdflqej637btfq53aeztwpnk3epxz64e7int3pcy5dxwa"
SUBNET_ID="ocid1.subnet.oc1.iad.aaaaaaaauuz6jqxlsduhikx37zo33zm5thxybhb2ppx7ltvulhfhq6ralzoa"
IMAGE_ID="ocid1.image.oc1.iad.aaaaaaaaawgpyvs3zh7tu5343gpj45yqcj6hosrmrgvo5xovc7dvjwgi4vaq"
SSH_KEY="/home/locoxella/.ssh/id_rsa.pub"
ADS=("nHMH:US-ASHBURN-AD-1" "nHMH:US-ASHBURN-AD-2" "nHMH:US-ASHBURN-AD-3")

echo "=================================================="
echo "Starting ARM Hunter in Ashburn (2 OCPUs / 12 GB RAM)..."
echo "Date: $(date)"
echo "Press Ctrl+C to stop."
echo "=================================================="

ATTEMPT=0

while true; do
    for AD in "${ADS[@]}"; do
        ((ATTEMPT++))
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [Attempt #$ATTEMPT] Trying $AD..."
        
        # Attempt launch
        RESULT=$(oci compute instance launch \
            --availability-domain "$AD" \
            --compartment-id "$COMPARTMENT_ID" \
            --shape "VM.Standard.A1.Flex" \
            --shape-config '{"ocpus": 2, "memoryInGBs": 12}' \
            --subnet-id "$SUBNET_ID" \
            --image-id "$IMAGE_ID" \
            --ssh-authorized-keys-file "$SSH_KEY" \
            --display-name "AlwaysFree-Ubuntu-ARM" \
            --assign-public-ip true 2>&1)

        # Check if successful
        if [[ $RESULT == *"lifecycle-state"* ]]; then
            echo "🎉 SUCCESS! VM is provisioning!"
            echo "$RESULT"
            exit 0
        elif [[ $RESULT == *"OutOfCapacity"* ]] || [[ $RESULT == *"Out of host capacity"* ]]; then
            echo "  └─ Out of capacity in $AD."
        elif [[ $RESULT == *"LimitExceeded"* ]]; then
            echo "  └─ ERROR: Limit exceeded for your tenancy. Check your Oracle Dashboard."
            echo "$RESULT"
            exit 1
        elif [[ $RESULT == *"NotAuthorizedOrNotFound"* ]] || [[ $RESULT == *"InvalidParameter"* ]]; then
            echo "  └─ ERROR: Configuration error (subnet/image/compartment)."
            echo "$RESULT"
            exit 1
        else
            MSG=$(echo "$RESULT" | grep -i "message" | head -n 1)
            if [ -n "$MSG" ]; then
                echo "  └─ Response: $MSG"
            else
                echo "  └─ Out of capacity / API retry required."
            fi
        fi
    done
    
    echo "[$(date +'%H:%M:%S')] Cycle complete. Waiting 60 seconds before next attempt..."
    sleep 60
done
