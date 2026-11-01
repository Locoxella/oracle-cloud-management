# 🌐 Network: VCN
resource "oci_core_vcn" "aether_network" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "Aether-Network"
  dns_label      = "locoxella"
}

# 🌐 Network: Internet Gateway
resource "oci_core_internet_gateway" "aether_internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.aether_network.id
  display_name   = "Internet gateway-locoxella"
  enabled        = true
}

# 🌐 Network: Route Table (Default Route Table for VCN)
resource "oci_core_default_route_table" "aether_default_route_table" {
  manage_default_resource_id = oci_core_vcn.aether_network.default_route_table_id
  display_name               = "default route table for locoxella"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.aether_internet_gateway.id
  }
}

# 🌐 Network: Public Subnet
resource "oci_core_subnet" "aether_subnet_public" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.aether_network.id
  cidr_block                 = "10.0.0.0/24"
  display_name               = "Aether-Subnet-Public"
  dns_label                  = "sub02060316490"
  route_table_id             = oci_core_default_route_table.aether_default_route_table.id
  security_list_ids          = [oci_core_security_list.aether_guard_list.id]
  prohibit_public_ip_on_vnic = false
}


# 🛡️ Security List
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
  target_subnet_id = oci_core_subnet.aether_subnet_public.id
  name             = "locoxella-bastion"

  client_cidr_block_allow_list = ["0.0.0.0/0"]
  max_session_ttl_in_seconds   = 10800
}

# 💻 Compute AMD (Atlas-Node-01)
resource "oci_core_instance" "atlas_node_01" {
  compartment_id      = var.compartment_id
  availability_domain = "nHMH:US-ASHBURN-AD-2"
  shape               = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    subnet_id        = oci_core_subnet.aether_subnet_public.id
    assign_public_ip = true
  }
}

# 💻 Compute ARM (AlwaysFree-Ubuntu-ARM)
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
    subnet_id        = oci_core_subnet.aether_subnet_public.id
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

# 💾 Block Storage (Atlas-Vault-01)
resource "oci_core_volume" "atlas_vault_01" {
  compartment_id      = var.compartment_id
  availability_domain = "nHMH:US-ASHBURN-AD-2"
  size_in_gbs         = 50
}
