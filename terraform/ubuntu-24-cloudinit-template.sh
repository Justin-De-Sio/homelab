#!/bin/bash

# Paramètres
VMID=8000
VMNAME="ubuntu-24-cloudinit-template"
IMG_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMG_FILE="noble-server-cloudimg-amd64.img"
STORAGE="local-lvm"
BRIDGE="vmbr0"

# 1. Télécharger l'image cloud Ubuntu 24.04
wget -O "$IMG_FILE" "$IMG_URL"

# 2. Créer la VM
qm create $VMID \
  --name $VMNAME \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=$BRIDGE

# 3. Importer le disque dans le storage (format qcow2 automatique)
qm importdisk $VMID $IMG_FILE $STORAGE

# 4. Attacher le disque importé comme scsi0
qm set $VMID \
  --scsihw virtio-scsi-pci \
  --scsi0 ${STORAGE}:vm-${VMID}-disk-0

# 5. Ajouter le disque Cloud-Init (nécessaire pour injecter SSH/user)
qm set $VMID --ide2 ${STORAGE}:cloudinit

# 6. Configurer l’ordre de boot sur scsi0
qm set $VMID --boot order=scsi0

# 7. Activer la console série (nécessaire pour voir le boot avec Cloud-Init)
qm set $VMID --serial0 socket --vga serial0

# 8. Convertir la VM en template
qm template $VMID

echo "✅ Template Ubuntu 24.04 créé avec succès : $VMNAME (VMID $VMID)"
