# VM Hunting Scripts Documentation

This folder contains scripts designed to automate the process of "hunting" for Oracle Cloud Always Free instances, which are often out of capacity.

## Scripts Overview

### 1. `arm_hunter.sh`

- **Purpose:** Attempts to provision an ARM-based Ampere A1 instance.
- **Resources requested:**
  - Shape: `VM.Standard.A1.Flex`
  - Config: 4 OCPUs, 24 GB RAM.
- **Behavior:**
  - Iterates through all three Availability Domains (ADs) in the US-Ashburn (IAD) region.
  - Retries ogni 60 secondi if capacity is unavailable (`OutOfCapacity`).
  - Exits on success or on `LimitExceeded` errors.
- **Execution:**

  ```bash
  nohup ./arm_hunter.sh > arm_hunter.log 2>&1 &
  ```

### 2. `amd_hunter.sh`

- **Purpose:** Attempts to provision an AMD-based Micro instance (the second free one).
- **Resources requested:**
  - Shape: `VM.Standard.E2.1.Micro`
- **Behavior:**
  - Iterates through ADs.
  - Retries ogni 60 secondi.
  - Exits on success (lifecycle-state appears) or critical error.
- **Execution:**

  ```bash
  nohup ./amd_hunter.sh > amd_2_hunter.log 2>&1 &
  ```

## Common Logic

Both scripts use a `while true` loop and the `oci compute instance launch` command. They redirect errors to `RESULT` to parse whether the error is a capacity issue or something else.

### How to use these scripts

1. Ensure `oci-cli` is configured with your credentials.
2. Grant execution permissions: `chmod +x *.sh`.
3. Run them in the background using `nohup` to keep them running after you logout.
4. Check the generated `.log` files to see progress.
