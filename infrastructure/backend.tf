terraform {
  backend "http" {
    address        = "https://git.solucionesaustral.com/api/v1/terraform/locoxella/oracle-cloud-management/tfstate"
    lock_address   = "https://git.solucionesaustral.com/api/v1/terraform/locoxella/oracle-cloud-management/tfstate"
    unlock_address = "https://git.solucionesaustral.com/api/v1/terraform/locoxella/oracle-cloud-management/tfstate"
    username       = "locoxella"
    # El password se pasará por línea de comandos o variable de entorno para seguridad
  }
}
