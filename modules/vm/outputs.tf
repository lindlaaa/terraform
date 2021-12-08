output "instance_ip" {
    value = proxmox_vm_qemu.c1-node[*].default_ipv4_address
}