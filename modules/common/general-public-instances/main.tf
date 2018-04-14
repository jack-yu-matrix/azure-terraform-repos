# batch create public visable azure instances
# create a resource group 
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"

  tags {
    environment = "${var.resource_env}"
  }
}

resource "azurerm_virtual_network" "network" {
  name                = "${var.resource_group_name}-network"
  address_space       = ["${var.virtual_network_cidr}"]
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  depends_on          = ["azurerm_resource_group.resource_group"]

  tags {
    environment = "${var.resource_env}"
  }
}

resource "azurerm_subnet" "publicsubnet" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = "${var.resource_group_name}-network"
  address_prefix       = "${var.public_subnet_cidr}"
  depends_on           = ["azurerm_virtual_network.network", "azurerm_resource_group.resource_group"]
}

resource "azurerm_public_ip" "publicip" {
  count                        = "${var.instances_count}"
  name                         = "${var.resource_group_name}-publicip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "static"
  depends_on                   = ["azurerm_subnet.publicsubnet", "azurerm_resource_group.resource_group"]

  tags {
    environment = "${var.resource_env}"
  }
}

resource "azurerm_network_security_group" "publicipnsg" {
  name                = "${var.resource_group_name}-publicipsg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  depends_on          = ["azurerm_resource_group.resource_group"]

  security_rule {
    name                       = "SSH00"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "112.81.47.25/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH01"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "180.169.57.41/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH02"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "180.169.57.42/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul-Dashboard10"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500"
    source_address_prefix      = "112.81.47.25/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul-Dashboard11"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500"
    source_address_prefix      = "180.169.57.41/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul-Dashboard12"
    priority                   = 1012
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500"
    source_address_prefix      = "180.169.57.42/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 1021
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "configserver"
    priority                   = 1022
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8888"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "dockerclient"
    priority                   = 1023
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2375"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "${var.resource_env}"
  }
}

resource "azurerm_network_interface" "nic" {
  count                     = "${var.instances_count}"
  name                      = "${var.resource_group_name}-nic-${count.index}"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${azurerm_network_security_group.publicipnsg.id}"

  ip_configuration {
    name                          = "${var.resource_group_name}-nic-configuration-${count.index}"
    subnet_id                     = "${azurerm_subnet.publicsubnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.publicip.*.id, count.index)}"
  }

  depends_on = ["azurerm_public_ip.publicip", "azurerm_resource_group.resource_group", "azurerm_network_security_group.publicipnsg"]

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

resource "azurerm_storage_account" "account" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.location}"
  account_replication_type = "LRS"
  account_tier             = "Standard"
  depends_on               = ["azurerm_resource_group.resource_group"]

  tags {
    environment = "${var.resource_env}"
  }
}

resource "azurerm_virtual_machine" "vm" {
  count                 = "${var.instances_count}"
  name                  = "${var.resource_group_name}-general-public-vm-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  vm_size               = "${var.vm_size}"

  storage_os_disk {
    name          = "${var.resource_group_name}-osdisk-${count.index}"
    caching       = "ReadWrite"
    create_option = "FromImage"

    #managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.3"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.resource_group_name}-vm-${count.index}"
    admin_username = "azureuser"
    custom_data    = "${file("${path.module}/../../template/cloud-init.yaml")}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.account.primary_blob_endpoint}"
  }

  tags {
    Name        = "${var.resource_group_name}-general-public-vm-${count.index}"
    Environment = "${var.resource_env}"
  }
}
