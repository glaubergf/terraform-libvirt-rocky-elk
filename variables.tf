variable "libvirt_disk_path" {
  description = "path for libvirt pool"
  default     = "/home/mcnd2/VMs/elastic"
}

variable "rocky_9_qcow2_url" {
  description = "rocky 9.3 image"
  default     = "https://download.rockylinux.org/pub/rocky/9.3/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2"
  #fonte da imagem: https://download.rockylinux.org/pub/rocky/
}

variable "vm_hostname" {
  description = "hostname of vm"
  default     = "tf-kvm-elk"
}
variable "vm_user" {
  description = "user of vm"
  default     = "elk"
}

variable "vm_password" {
  description = "password of vm"
  default     = "elk123"
}

variable "vm_vol_size" {
  description = "size of vm disc"
  default     = { size = "21474836480" } # 10737418240 byte == 10³ == 10 GiB
}

variable "vm_memory" {
  description = "vm memory available"
  default     = "4096"
}

variable "vm_cpu" {
  description = "vm cpus available"
  default     = "4"
}

variable "vm_ip" {
  description = "ip of vm"
  default     = ["192.100.20.200"]
}

variable "vm_mac" {
  description = "mac address of vm"
  default     = { mac = "52:54:00:0E:60:BB" }
}

variable "ssh_username" {
  description = "the ssh user to use"
  default     = "elk"
}

variable "ssh_private_key" {
  description = "the private key to use"
  default     = "~/.ssh/debiandesk_id_rsa"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "configs" {
  description = "List of files to copy"
  type        = list(string)
  default     = ["motd_elk", "config_motd.sh"]
}

variable "scripts" {
  description = "List of scripts to copy and run"
  type        = list(string)
  default     = ["basic.sh", "install_elasticsearch.sh", "install_kibana.sh", "install_logstash.sh"]
}
