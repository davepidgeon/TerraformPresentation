# Configure the Microsoft Azure Provider
provider "azurerm" {
  version = "~>2.0"
  features {}
}

# Create the resource group
resource "azurerm_resource_group" "myterraformgroup" {
  name     = "TerraformPresentationResourceGroup"
  location = "uksouth"

  tags = {
    costowner = "I&O"
    service   = "Demo"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "TerraformPresentationvNet"
  address_space       = ["192.168.0.0/20"]
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  tags = {
    costowner = "I&O"
    service   = "Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "TerraformPresentationSubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["192.168.1.0/24"]
}

# Generate a random sting to add to the FQDN DNS record
resource "random_string" "web1" {
  length  = 5
  upper   = false
  lower   = true
  number  = true
  special = false
}
resource "random_string" "lb" {
  length  = 5
  upper   = false
  lower   = true
  number  = true
  special = false
}

# Create public IPs
resource "azurerm_public_ip" "WebPublicIP" {
  name                = "WebPublicIP"
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Dynamic"
  domain_name_label   = "terraformpresentation${random_string.web1.result}"

  tags = {
    costowner = "I&O"
    service   = "Demo"
  }
}
resource "azurerm_public_ip" "LBPublicIP" {
  name                = "LBPublicIP"
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Dynamic"
  domain_name_label   = "terraformpresentation${random_string.lb.result}"

  tags = {
    costowner = "I&O"
    service   = "Demo"
  }
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "TerraformPresentationNSG"
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

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

  security_rule {
    name                       = "allow-http"
    description                = "allow-http"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    costowner = "I&O"
    service   = "Demo"
  }
}

# Create network interface
resource "azurerm_network_interface" "web1nic" {
  name                = "TerraformPresentationNIC"
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "web1nicConfiguration"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.WebPublicIP.id
  }

  tags = {
    costowner = "I&O"
    service   = "Demo"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.web1nic.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.myterraformgroup.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.myterraformgroup.name
  location                 = "uksouth"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    costowner = "I&O"
    service   = "Demo"
  }
}

# Create an SSH key
resource "tls_private_key" "mySSHKey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a data template Bash file to  bootstrap installing a webserver
data "template_file" "web-page-init" {
  template = file("enable-web-server1.sh")
}

data "template_file" "web-page-init2" {
  template = file("enable-web-server2.sh")
}

# Create avaliability set
resource "azurerm_availability_set" "webavset" {
 name                         = "webavset"
 location                     = "uksouth"
 resource_group_name          = azurerm_resource_group.myterraformgroup.name
 platform_fault_domain_count  = 2
 platform_update_domain_count = 2
 managed                      = true
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "web1vm" {
  name                  = "web1"
  location              = "uksouth"
  availability_set_id   = azurerm_availability_set.webavset.id
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.web1nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "OS"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  computer_name                   = "TerraformPresentationVM"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  custom_data                     = base64encode(data.template_file.web-page-init.rendered)

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.mySSHKey.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

  tags = {
    costowner = "I&O"
    service   = "Demo"
  }
}

resource "azurerm_network_interface" "web2nic" {
    name                = "web2nic"
    location            = "uksouth"
    resource_group_name = azurerm_resource_group.myterraformgroup.name
  
    ip_configuration {
      name                          = "web2nicConfiguration"
      subnet_id                     = azurerm_subnet.myterraformsubnet.id
      private_ip_address_allocation = "Dynamic"
    }
  
    tags = {
      costowner = "I&O"
      service   = "Demo"
    }
  }

resource "azurerm_network_interface_security_group_association" "web2nic" {
    network_interface_id      = azurerm_network_interface.web2nic.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
  }
  

resource "azurerm_linux_virtual_machine" "web2vm" {
    name                  = "web2"
    location              = "uksouth"
    availability_set_id   = azurerm_availability_set.webavset.id
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.web2nic.id]
    size                  = "Standard_DS1_v2"
  
    os_disk {
      name                 = "OSweb2"
      caching              = "ReadWrite"
      storage_account_type = "Premium_LRS"
    }
  
    source_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04.0-LTS"
      version   = "latest"
    }
  
    computer_name                   = "web2"
    admin_username                  = "azureuser"
    disable_password_authentication = true
    custom_data                     = base64encode(data.template_file.web-page-init2.rendered)
  
    admin_ssh_key {
      username   = "azureuser"
      public_key = tls_private_key.mySSHKey.public_key_openssh
    }
  
    boot_diagnostics {
      storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }
  
    tags = {
      costowner = "I&O"
      service   = "Demo"
    }
  }

resource "azurerm_lb" "TerraformPresentationLB" {
  name                = "TerraformPresentationLB"
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  frontend_ip_configuration {
    name                 = "LBPublicIP"
    public_ip_address_id = azurerm_public_ip.LBPublicIP.id
  }
}

resource "azurerm_lb_backend_address_pool" "TerraformPresentationLB" {
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  loadbalancer_id     = azurerm_lb.TerraformPresentationLB.id
  name                = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "TerraformPresentationLB" {
  network_interface_id    = azurerm_network_interface.web1nic.id
  ip_configuration_name   = "web1nicConfiguration"
  backend_address_pool_id = azurerm_lb_backend_address_pool.TerraformPresentationLB.id
}

resource "azurerm_network_interface_backend_address_pool_association" "web2" {
  network_interface_id    = azurerm_network_interface.web2nic.id
  ip_configuration_name   = "web2nicConfiguration"
  backend_address_pool_id = azurerm_lb_backend_address_pool.TerraformPresentationLB.id
}

resource "azurerm_lb_rule" "TerraformPresentationLB" {
  resource_group_name            = azurerm_resource_group.myterraformgroup.name
  loadbalancer_id                = azurerm_lb.TerraformPresentationLB.id
  name                           = "Web"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LBPublicIP"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.TerraformPresentationLB.id
  probe_id                       = azurerm_lb_probe.TerraformPresentationLB.id
  
}


resource "azurerm_lb_probe" "TerraformPresentationLB" {
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  loadbalancer_id     = azurerm_lb.TerraformPresentationLB.id
  name                = "http"
  port                = 80
    protocol            = "Http"
  request_path        = "/"
}

# Output the URL of the website we've deployed
output "public_ip_address" {
  value = "http://${azurerm_public_ip.LBPublicIP.fqdn}"
}