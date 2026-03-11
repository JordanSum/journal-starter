resource "azurerm_resource_group" "rg" {
  name     = "l2c-rg"
  location = "West US"
}

resource "azurerm_virtual_network" "l2c-vnet" {
  name                = "l2c-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.l2c-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
resource "azurerm_private_dns_zone" "private-dns" {
  name                = "privatedns.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns-zone-link" {
  name                  = "l2cprivateDnsZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.private-dns.name
  virtual_network_id    = azurerm_virtual_network.l2c-vnet.id
  resource_group_name   = azurerm_resource_group.rg.name
  depends_on            = [azurerm_subnet.subnet]
}

# Create a container registry
resource "azurerm_container_registry" "acr" {
  name                = "l2cacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Create a AKS cluster
resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "example-aks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned" # Use a system-assigned identity
  }
}

# Assign the AcrPull role to the AKS managed identity on the ACR
resource "azurerm_role_assignment" "example_acrpull_role" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
}

# Create a PostgreSQL flexible server
resource "azurerm_postgresql_flexible_server" "fs" {
  name                          = "l2c-psql"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "15"
  public_network_access_enabled = true
  administrator_login           = var.psqlusername
  administrator_password        = var.psqlpassword

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"

}

resource "azurerm_postgresql_flexible_server_database" "db" {
    name = "career_journal"
    server_id = azurerm_postgresql_flexible_server.fs.id
    collation = "en_US.utf8"
    charset = "UTF8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_pip" {
  name                = "allow_pip"
  server_id         = azurerm_postgresql_flexible_server.fs.id
  start_ip_address    = var.pip
  end_ip_address      = var.pip
}