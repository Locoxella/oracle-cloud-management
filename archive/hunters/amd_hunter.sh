#!/bin/bash

# Configuration
COMPARTMENT_ID="ocid1.tenancy.oc1..aaaaaaaacdo7v2uzdflqej637btfq53aeztwpnk3epxz64e7int3pcy5dxwa"
SUBNET_ID="ocid1.subnet.oc1.iad.aaaaaaaauuz6jqxlsduhikx37zo33zm5thxybhb2ppx7ltvulhfhq6ralzoa"
IMAGE_ID="ocid1.image.oc1.iad.aaaaaaaaz7br7vztzzjvyfxiqbu2fumsuegfkofpyeapf7tamqxpwmyt5ygq"
SSH_KEY="/home/locoxella/.ssh/id_rsa.pub"
ADS=("nHMH:US-ASHBURN-AD-1" "nHMH:US-ASHBURN-AD-3")

echo "Starting AMD Hunter in Ashburn..."
echo "Press Ctrl+C to stop."

while true; do
    for AD in "${ADS[@]}"; do
        echo "[$(date +%T)] Trying $AD..."
        
        # Attempt launch (Note: E2.1.Micro doesn't use --shape-config)
        RESULT=$(oci compute instance launch \
            --availability-domain "$AD" \
            --compartment-id "$COMPARTMENT_ID" \
            --shape "VM.Standard.E2.1.Micro" \
            --subnet-id "$SUBNET_ID" \
            --image-id "$IMAGE_ID" \
            --ssh-authorized-keys-file "$SSH_KEY" \
            --display-name "AlwaysFree-Ubuntu-AMD-2" \
            --assign-public-ip true 2>&1)

        # Check if successful
        if [[ $RESULT == *"lifecycle-state"* ]]; then
            echo "SUCCESS! VM is provisioning."
            echo "$RESULT"
            exit 0
        elif [[ $RESULT == *"OutOfCapacity"* ]]; then
            echo "  - Out of capacity."
        elif [[ $RESULT == *"LimitExceeded"* ]]; then
            echo "  - ERROR: You hit a limit. Check your Oracle Dashboard."
            exit 1
        else
            echo "  - Unexpected error or timeout. Retrying..."
        fi
    done
    
    echo "None available. Sleeping for 60 seconds..."
    sleep 60
done
