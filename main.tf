terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "my_rg" {
  name = "interview4-rg"
  location = "westeurope"
}

resource "azurerm_virtual_network" "vnet" {
    name                = "virtual-network"
    resource_group_name = azurerm_resource_group.my_rg.name
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.my_rg.location
}

resource "azurerm_subnet" "subnet" {
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.my_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_network_interface" "network_interface" {
  name                = "my-network-interface"
  location            = azurerm_resource_group.my_rg.location
  resource_group_name = azurerm_resource_group.my_rg.name

  ip_configuration {
    name                          = "my-configuration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_ip.id
  }
}

resource "azurerm_public_ip" "my_ip" {
  name                = "my-public-ip"
  resource_group_name = azurerm_resource_group.my_rg.name
  location            = azurerm_resource_group.my_rg.location
  allocation_method   = "Dynamic"
  }

resource "azurerm_network_security_group" "my_secuirty_group" {
  name                = "my-security-group"
  location            = azurerm_resource_group.my_rg.location
  resource_group_name = azurerm_resource_group.my_rg.name

  security_rule {
    name                       = "access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "80.230.158.197"
    destination_address_prefix = "*"
  }
}

resource "azurerm_linux_virtual_machine" "my_vm" {
  name                  = "my-vm"
  location              = azurerm_resource_group.my_rg.location
  resource_group_name   = azurerm_resource_group.my_rg.name
  network_interface_ids = [azurerm_network_interface.network_interface.id]
  size                  = "Standard_B2s"
  admin_username        = "adminuser"


  admin_ssh_key{
    username  = "adminuser"
    public_key = file("my-keys.pub")
  }

  source_image_reference  {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7-LVM"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_network_interface_security_group_association" "ni_sg_association" {
  network_interface_id      = azurerm_network_interface.network_interface.id
  network_security_group_id = azurerm_network_security_group.my_secuirty_group.id
}

resource "azurerm_virtual_machine_extension" "my_extension" {
  name                 = "my-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.my_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "yum install docker -y"
    }
SETTINGS

}