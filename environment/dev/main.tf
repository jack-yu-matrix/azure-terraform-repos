# Configure the Azure Provider
# NOTE: if you defined these values as environment variables, you do not have to include this block
provider "azurerm" {

version = "~> 0.3.3" 
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  environment     = "${var.rm_env}"
}

# create a resource group 
resource "azurerm_resource_group" "microservice" {
    name = "${var.resource_group_name}"
    location = "${var.location}"
    tags {
        environment = "${var.resource_env}"
    }
}



