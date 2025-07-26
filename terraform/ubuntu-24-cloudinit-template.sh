#!/bin/bash

VMID=8000
VMNAME="ubuntu-24-cloudinit-template"
IMG_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMG_FILE="noble-server-cloudimg-amd64.img"
STORAGE="local-lvm"
BRIDGE="vmbr0"

# 1. Download Ubuntu 24.04 cloud image
wget -O "$IMG_FILE" "$IMG_URL"

# 2. Create the VM
qm create $VMID \
  --name $VMNAME \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=$BRIDGE

# 3. Import disk to storage (qcow2 format automatically)
qm importdisk $VMID $IMG_FILE $STORAGE

# 4. Attach the imported disk as scsi0
qm set $VMID \
  --scsihw virtio-scsi-pci \
  --scsi0 ${STORAGE}:vm-${VMID}-disk-0

# 5. Add Cloud-Init disk (required to inject SSH/user configuration)
qm set $VMID --ide2 ${STORAGE}:cloudinit

# 6. Configure boot order to scsi0
qm set $VMID --boot order=scsi0

# 7. Enable serial console (required to see boot process with Cloud-Init)
qm set $VMID --serial0 socket --vga serial0

# 8. Convert VM to template
qm template $VMID