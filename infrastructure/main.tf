# 🌐 Red (VCN existente)
resource "oci_core_vcn" "aether_network" {
  compartment_id = var.compartment_id
}

# 💻 Cómputo (Existente)
resource "oci_core_instance" "atlas_node_01" {
  compartment_id      = var.compartment_id
  availability_domain = "nHMH:US-ASHBURN-AD-2"
  shape               = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    subnet_id        = "ocid1.subnet.oc1.iad.aaaaaaaauuz6jqxlsduhikx37zo33zm5thxybhb2ppx7ltvulhfhq6ralzoa"
    assign_public_ip = false
  }
}

# 💾 Almacenamiento (Existente)
resource "oci_core_volume" "atlas_vault_01" {
  compartment_id      = var.compartment_id
  availability_domain = "nHMH:US-ASHBURN-AD-2"
  size_in_gbs         = 50
}
