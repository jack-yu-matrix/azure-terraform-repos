# Configure the Azure Provider
# NOTE: if you defined these values as environment variables, you do not have to include this block
provider "azurerm" {

version = "~> 1.3.2" 
  subscription_id = "47ad3a05-bec5-4082-adcd-7d8234132066"
  client_id       = "341796f2-9540-4fd7-a950-c755d0614f49"
  client_secret   = "bohS4Ot4pGXgB8MArWGmngJdYIUaw4qBEMGy77eKix0="
  tenant_id       = "990750a6-9a15-4d77-88b7-fbb034d63835"
  environment     = "china"
}

# create a resource group 
resource "azurerm_resource_group" "springcloud" {
    name = "cndev-ms-springcloud"
    location = "China North"
}