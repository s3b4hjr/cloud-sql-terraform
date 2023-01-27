locals {
  default_labels = {
    organization = var.organization
    environment  = var.environment
    context      = "teste"
  }
}

resource "google_compute_global_address" "private_ip_address" {
  provider      = google-beta
  project       = "tc-terraform-test"
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = data.google_compute_network.host_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = data.google_compute_network.host_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on = [
    google_compute_global_address.private_ip_address,
  ]
}

data "google_compute_network" "host_network" {
  name    = "teste-vpc"
  project = "tc-terraform-test"
}

module "mysqls" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version = "13.0.1"


  for_each = { for mysql in var.mysqls : mysql.name => mysql }

  name                 = try(each.value.name, null)
  random_instance_name = false
  database_version     = try(each.value.database_version, "MYSQL_5_6")
  project_id           = "tc-terraform-test"
  zone                 = try(each.value.zone, null)
  region               = try(each.value.region, var.region)
  tier                 = try(each.value.tier, "db-n1-standard-1")
  pricing_plan         = try(each.value.pricing_plan, "PER_USE")
  deletion_protection  = try(each.value.deletion_protection, false)
  availability_type    = "ZONAL"

  enable_default_db    = try(each.value.enable_default_db, true)
  db_name              = try(each.value.db_name, true)
  db_charset           = try(each.value.db_charset, "utf8")
  db_collation         = try(each.value.db_collation, "utf8_general_ci")
  additional_databases = try(each.value.additional_databases, [])

  enable_default_user = try(each.value.enable_default_user, true)
  user_name = try(each.value.user_name, "root")
  user_host           = try(each.value.user_host, null)
  user_password    = try(each.value.user_password, null)
  additional_users = try(each.value.additional_users, [])

  disk_autoresize       = try(each.value.disk_autoresize, true)
  disk_autoresize_limit = try(each.value.disk_autoresize_limit, 0)
  disk_size             = try(each.value.disk_size, 10)
  disk_type             = try(each.value.disk_type, "PD_SSD")

  backup_configuration = try(each.value.backup_configuration, {
    binary_log_enabled             = true
    enabled                        = true
    start_time                     = "03:00"
    location                       = null
    transaction_log_retention_days = null
    retained_backups               = "15"
    retention_unit                 = null
  })

  maintenance_window_day          = try(each.value.maintenance_window_day, 1)
  maintenance_window_hour         = try(each.value.maintenance_window_hour, 04)
  maintenance_window_update_track = try(each.value.maintenance_window_update_track, "canary")

  ip_configuration = try(each.value.ip_configuration, {
    authorized_networks = []
    ipv4_enabled        = true
    private_network     = data.google_compute_network.host_network.id 
    require_ssl         = false
    allocated_ip_range = google_compute_global_address.private_ip_address.name
  })

  // Optional: used to enforce ordering in the creation of resources.
  database_flags = try(each.value.database_flags, [])
  user_labels    = merge(local.default_labels, {})

  create_timeout = "15m"
  delete_timeout = "15m"
}
