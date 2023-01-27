locals {
  organization = "s3b4h"
  environment  = "development"
  project_name = "tc-terraform-test"
  project_id   = "tc-terraform-test"
  region       = "us-central1"
}

data "google_compute_global_address" "my_address" {
  name = "servicenetworking-googleapis-com"
}

data "google_compute_network" "host_network" {
  name    = "teste-vpc"
  project = "tc-terraform-test"
}

module "cloud-sql" {
  source = "./modules/sql"

  organization = local.organization
  environment  = local.environment
  region       = local.region
  project_id   = local.project_id

  mysqls = [
    # {
    #   name : "sql00",
    #   zone : "us-central1-a",
    #   region : "us-central1",
    #   tier: "db-f1-micro",
    # },
    {
      name : "sql01",
      zone : "us-central1-a",
      region : "us-central1",
      tier : "db-n1-standard-1",
      database_version : "MYSQL_8_0",
      ip_configuration = {
        authorized_networks = []
        ipv4_enabled        = false
        private_network     = data.google_compute_network.host_network.id 
        require_ssl         = false
        allocated_ip_range  = data.google_compute_global_address.my_address.address        
      }
    }
  ]
}

