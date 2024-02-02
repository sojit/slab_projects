#!/bin/bash
#set -x 
#hostname kmnode01
#virsh net-dhcp-leases kub-network


# Check if all required arguments are provided
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <vm_name> <memory> <cpu> <disk_size>"
  exit 1
fi

# Assign command line arguments to variables
VM_NAME="$1"
VM_MEMORY="$2"
VM_CPU="$3"
BASE_DISK_SIZE="$4"
NETWORK_NAME="kub-network"  


# Debian qcow2 image path and cloud-init ISO path
deb_qcow2_path="https://cloud.debian.org/images/cloud/buster/20190909-10/debian-10-generic-amd64-20190909-10.qcow2"
cloud_init="~/Documents/kvm_storage/seed-init.iso"
qcow_name=$(basename "$deb_qcow2_path")

# Paths for storing images and VMs
image_storage_path="~/Documents/disk_images"
vm_storage_path="~/Documents/kvm_storage"


#move the cloud image to the correct local storage directory path
vm_name="${VM_NAME}_$qcow_name"
function image_copy () {
     cp "$image_storage_path/$qcow_name"  "$vm_storage_path/$vm_name"
}

#check if the file exists
if [[ ! -f "$image_storage_path/$qcow_name" ]]; then
    # If the file does not exist, download it, then copy to the desired location
    if wget  "$deb_qcow2_path" -O "$image_storage_path/$qcow_name" ; then
    echo "File downloaded successfully!"
    image_copy
    fi    
elif [[ -f "$image_storage_path/$qcow_name" ]] && [[ ! -f "$vm_storage_path/$vm_name" ]]; then
    # If the image file exists but the VM file does not, then copy the image 
    image_copy
    
fi

#create vm based on the provided arguments
virt-install  \
   --name "$VM_NAME" \
   --memory "$VM_MEMORY" \
   --vcpus "$VM_CPU" \
   --disk path="$vm_storage_path/$vm_name",size="$BASE_DISK_SIZE" \
   --network network="$NETWORK_NAME" \
   --os-variant ubuntu19.04 \
   --graphics none --noautoconsole \
   --console pty,target_type=virtio \
   --serial pty  \
   --cdrom="$cloud_init"
