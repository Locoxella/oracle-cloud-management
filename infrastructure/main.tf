# 🌐 Red (VCN existente)
resource "oci_core_vcn" "aether_network" {
  compartment_id = var.compartment_id
}

# 🛡️ Lista de Seguridad
resource "oci_core_security_list" "aether_guard_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.aether_network.id
  display_name   = "Aether-Guard-List"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "1"
    source   = "0.0.0.0/0"
    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    protocol = "1"
    source   = "10.0.0.0/16"
    icmp_options {
      type = 3
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "10.0.0.0/16"
    tcp_options {
      min = 3000
      max = 3000
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "Allow Gitea SSH"
    tcp_options {
      min = 2222
      max = 2222
    }
  }

  ingress_security_rules {
    protocol    = "all"
    source      = "10.0.0.0/16"
    description = "Allow Internal VCN all traffic"
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    description = "Allow WireGuard VPN"
    udp_options {
      min = 51820
      max = 51820
    }
  }
}

# 🚪 Bastion
resource "oci_bastion_bastion" "locoxella_bastion" {
  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_id
  target_subnet_id = "ocid1.subnet.oc1.iad.aaaaaaaauuz6jqxlsduhikx37zo33zm5thxybhb2ppx7ltvulhfhq6ralzoa"
  name             = "locoxella-bastion"

  client_cidr_block_allow_list = ["0.0.0.0/0"]
  max_session_ttl_in_seconds   = 10800
}

# 💻 Cómputo AMD (Atlas-Node-01)
resource "oci_core_instance" "atlas_node_01" {
  compartment_id      = var.compartment_id
  availability_domain = "nHMH:US-ASHBURN-AD-2"
  shape               = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    subnet_id        = "ocid1.subnet.oc1.iad.aaaaaaaauuz6jqxlsduhikx37zo33zm5thxybhb2ppx7ltvulhfhq6ralzoa"
    assign_public_ip = true
  }
}

# 💻 Cómputo ARM (AlwaysFree-Ubuntu-ARM)
resource "oci_core_instance" "alwaysfree_ubuntu_arm" {
  compartment_id      = var.compartment_id
  availability_domain = "nHMH:US-ASHBURN-AD-1"
  display_name        = "AlwaysFree-Ubuntu-ARM"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  create_vnic_details {
    subnet_id        = "ocid1.subnet.oc1.iad.aaaaaaaauuz6jqxlsduhikx37zo33zm5thxybhb2ppx7ltvulhfhq6ralzoa"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1.iad.aaaaaaaaawgpyvs3zh7tu5343gpj45yqcj6hosrmrgvo5xovc7dvjwgi4vaq"
  }

  lifecycle {
    ignore_changes = [
      source_details,
      metadata,
    ]
  }
}

# 💾 Almacenamiento (Existente)
resource "oci_core_volume" "atlas_vault_01" {
  compartment_id      = var.compartment_id
  availability_domain = "nHMH:US-ASHBURN-AD-2"
  size_in_gbs         = 50
}
