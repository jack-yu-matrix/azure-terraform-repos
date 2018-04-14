# Configure the Azure Provider
# NOTE: if you defined these values as environment variables, you do not have to include this block
provider "azurerm" {
  version         = "~> 0.3.3"
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  environment     = "${var.rm_env}"
}

module general-public-instances {
  source               = "../../modules/common/general-public-instances"
  resource_group_name  = "${var.resource_group_name}"
  location             = "${var.location}"
  instances_count      = 4
  resource_env         = "${var.resource_env}"
  virtual_network_cidr = "${var.virtual_network_cidr}"
  public_subnet_cidr   = "${var.public_subnet_cidr}"
  vm_size              = "${var.general_public_instances}"
  key_data             = "${var.key_data}"
}
