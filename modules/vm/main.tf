terraform {
    required_providers {
      proxmox = {
          source = "Telmate/proxmox"
          version = "2.9.3"
      }
    }
}

provider "proxmox" {
  pm_api_url = "https://pve.averylindley.com:8006/api2/json"
  pm_api_token_id = "terraform-prov@pve!terraformpve"
  pm_api_token_secret = "9333e62b-cc20-4c02-ad06-53d5789d15fb"
  pm_debug = true
  pm_tls_insecure = true
  # pm_log_enable = true
  # pm_log_file = "terraform-plugin-proxmox.log"
  # pm_log_levels =  {
  #     _default = "debug"
  #     _capturelog = ""
  # }
}

# Create the VM
resource "proxmox_vm_qemu" "c1-node" {

  count = var.amount
  name = "n${count.index}"
  target_node = "pve"

  # Clone from debian-cloudinit template
  clone = "VM 9000"
  os_type = "cloud-init"

  # Cloud init options
  cicustom = "user=snip:snippets/ansible-cloud-init.cfg.yml"
  ipconfig0 = "ip=192.168.100.${count.index}/16,gw=192.168.1.1"

  memory       = 2048
  agent        = 1

  # Set the boot disk paramters
  bootdisk = "scsi0"
  scsihw       = "virtio-scsi-pci"

  disk {
    size            = "10G"
    type            = "scsi"
    storage         = "local-lvm"
  }

  # Set the network
  network {
    model = "virtio"
    bridge = "vmbr1"
  }

  # Ignore changes to the network
  ## MAC address is generated on every apply, causing
  ## TF to think this needs to be rebuilt on every apply
  lifecycle {
     ignore_changes = [
       network
     ]
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/hosts.tmpl", {
      ips          = proxmox_vm_qemu.c1-node[*].default_ipv4_address,
  })
  filename = "hosts.yaml"
}