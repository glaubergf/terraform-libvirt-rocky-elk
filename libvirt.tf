/*NOTAS:

  NOTA 1: Caso houver um erro similar como por exemplo:

    Error: "...Could not open '/opt/kvm/pool1/rocky-qcow2': Permission denied"
    Error: "error creating libvirt domain: internal error: process exited while connecting to monitor: ..."

    Habilite a linha descomentando-a, deixando com o valor como 'security_driver = none' no arquivo '/etc/libvirt/qemu.conf'.
    Em seguida deverá ser reiniciado o deamon 'libvirtd'.
    Fonte: https://stackoverflow.com/questions/63984912/coreos-image-fails-to-load-ignition-file-via-libvirt-permission-denied/70563027#70563027

  NOTA 2: Video YouTube Terraform com KVM/Libvirt
   
   Fonte: https://www.youtube.com/watch?v=uJ6PQD2n1vU&ab_channel=SavantTecnologia

  Referencias:
  https://blog.ruanbekker.com/blog/2020/10/08/using-the-libvirt-provisioner-with-terraform-for-kvm/
  https://www.desgehtfei.net/en/quick-start-kvm-libvirt-vms-with-terraform-and-ansible-part-1-2/
  https://github.com/dmacvicar/terraform-provider-libvirt
  https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs
  https://blog.stephane-robert.info/post/terraform-provider-libvirt/
  https://blog.stephane-robert.info/post/terraform-libvirt-resize-image/
*/

provider "libvirt" {
  uri = "qemu:///system"
  #uri = "qemu+ssh://root@192.100.20.200/system"
}

resource "libvirt_pool" "elastic" {
  name = "elastic"
  type = "dir"
  path = var.libvirt_disk_path
}

resource "libvirt_volume" "rocky-base" {
  name   = "rocky-base"
  source = var.rocky_9_qcow2_url
  pool   = libvirt_pool.elastic.name
  format = "qcow2"
}

resource "libvirt_volume" "rocky-qcow2" {
  name           = "rocky-qcow2"
  base_volume_id = libvirt_volume.rocky-base.id
  pool           = libvirt_pool.elastic.name
  size           = var.vm_vol_size.size
}

data "template_file" "user_data" {
  template = file("${path.module}/configs/cloud_init.yml")
}

data "template_file" "network_config" {
  template = file("${path.module}/configs/network_config.yml")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.elastic.name
}

resource "libvirt_domain" "domain-rocky" {
  name   = var.vm_hostname
  memory = var.vm_memory
  vcpu   = var.vm_cpu

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  cpu {
    mode = "host-passthrough"
  }

  autostart = false

  disk {
    volume_id = libvirt_volume.rocky-qcow2.id
    scsi      = "true"
  }

  network_interface {
    network_name   = "r2-net-in"
    wait_for_lease = true
    hostname       = var.vm_hostname
    addresses      = var.vm_ip
    mac            = var.vm_mac.mac
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  connection {
    type                = "ssh"
    user                = var.ssh_username
    host                = libvirt_domain.domain-rocky.network_interface[0].addresses[0]
    private_key         = file(var.ssh_private_key)
    bastion_host        = var.vm_hostname
    bastion_user        = var.vm_user
    bastion_private_key = file("~/.ssh/id_rsa")
    timeout             = "1m"
  }
}

resource "null_resource" "swap_setup" {
  provisioner "remote-exec" {
    inline = [
      "sudo fallocate -l 2G /swapfile",
      "sudo chmod 600 /swapfile",
      "sudo mkswap /swapfile",
      "sudo swapon /swapfile",
      "echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab"
    ]

    connection {
      type     = "ssh"
      user     = var.vm_user
      password = var.vm_password
      host     = libvirt_domain.domain-rocky.network_interface[0].addresses[0]
    }
  }
}

resource "null_resource" "copy_file" {
  #count = var.vm_count

  for_each = toset(var.configs)
  provisioner "file" {
    source      = "/home/mcnd2/Projetos/terraform-libvirt-rocky-elk/configs/${each.value}"
    destination = "/home/elk/${each.value}"

    connection {
      type     = "ssh"
      user     = var.vm_user
      password = var.vm_password
      host     = libvirt_domain.domain-rocky.network_interface[0].addresses[0]
      #host = libvirt_domain.domain-rocky[count.index].network_interface[0].addresses[0]
    }
  }

  /*for_each = toset(var.scripts)
  provisioner "file" {
    source      = "/home/mcnd2/Projetos/terraform-libvirt-rocky-elk/scripts/${each.value}"
    destination = "/home/elk/${each.value}"

    connection {
      type     = "ssh"
      user     = var.vm_user
      password = var.vm_password
      host     = libvirt_domain.domain-rocky.network_interface[0].addresses[0]
      #host = libvirt_domain.domain-rocky[count.index].network_interface[0].addresses[0]
    }
  }*/
}

resource "null_resource" "ansible_provisioner" {
  depends_on = [
    libvirt_domain.domain-rocky,
    null_resource.swap_setup,
    null_resource.copy_file,
  ]

  provisioner "local-exec" {
    command     = "ansible-playbook -i hosts main.yml"
    working_dir = "/home/mcnd2/Projetos/ansible-elk/"
  }
}
