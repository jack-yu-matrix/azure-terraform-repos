# Configure the Azure Provider
# NOTE: if you defined these values as environment variables, you do not have to include this block
provider "azurerm" {

version = "~> 1.3.2" 
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  environment     = "${var.environment}"
}

# create a resource group 
resource "azurerm_resource_group" "microservice" {
    name = "${var.resource_group_name}"
    location = "${var.location}"
}
