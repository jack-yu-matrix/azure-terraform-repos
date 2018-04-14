# batch create public visable azure instances
# create a resource group 
resource "azurerm_resource_group" "microservice" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"

  tags {
    environment = "${var.resource_env}"
  }
}

resource "azurerm_virtual_network" "microservicenetwork" {
  name                = "${var.resource_group_name}-network"
  address_space       = ["${var.virtual_network_cidr}"]
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  tags {
    environment = "${var.resource_env}"
  }
}

resource "azurerm_subnet" "microservicesubnet" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = "${var.resource_group_name}-network"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "microservicepublicip" {
  name                         = "${var.resource_group_name}-publicip-001"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "dynamic"

  tags {
    environment = "${var.resource_env}"
  }
}

resource "azurerm_network_security_group" "microservicepublicipnsg" {
  name                = "${var.resource_group_name}-publicipsg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "${var.resource_env}"
  }
}

resource "azurerm_network_interface" "microservicemnic" {
  name                = "${var.resource_group_name}-nic"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "${var.resource_group_name}-nic-configuration"
    subnet_id                     = "${azurerm_subnet.microservicesubnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.microservicepublicip.id}"
  }

  tags {
    environment = "${var.resource_env}"
  }
}

resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${var.resource_group_name}"
  }

  byte_length = 8
}

resource "azurerm_storage_account" "microserviceaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.location}"
  account_replication_type = "LRS"
  account_tier             = "Standard"

  tags {
    environment = "${var.resource_env}"
  }
}

resource "azurerm_virtual_machine" "microservicevm" {
  name                  = "${var.resource_group_name}-vm-001"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${azurerm_network_interface.microservicemnic.id}"]
  vm_size               = "Standard_DS2"

  storage_os_disk {
    name              = "${var.resource_group_name}-osdisk-001"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.3"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.resource_group_name}-vm-001"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCLd8nGPmpvfaDGsC3XTKXD6TzIvWeSWM+IuP0VCZdzDDSvk0ir9rlTNnWtubJVkMryf0GjUG5qTLeoprzUzB1bNVZuyAgv+ZHeSFnKnMO20q7022Q6LMqZizIs1jIw5rg28A6uF/7B3/dCcJOCIYHz7+gqMPInoQEYdt83tFpAnH/YKyS6FodpNkLikyayMRDt4FDOdW+o3Gnm9TtINu0HDZBhXhXT22vdLklmBqsOdIbKxE2A5ikEDQ6p7rVgQPG3w7FrfVy7G5QDWkuRxllHiPY7EuwVVxmnbdRKUUEfcSrzvaJYUw+FGQR5oQ4Oc5wNPUQePc3qgB2TtAnQ1xar"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.microserviceaccount.primary_blob_endpoint}"
  }

  tags {
    environment = "${var.resource_env}"
  }
}
