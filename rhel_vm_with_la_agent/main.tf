resource "azurerm_network_interface" "interface" {
  name = "${var.vm_name}-vnic1"
  location = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name = "internal"
    subnet_id = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${var.publicip_id != "" ? var.publicip_id : null}"
  }
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name = var.vm_name
  resource_group_name = var.rg_name
  location = var.location
  size = var.vm_size
  admin_username = var.vm_user
  admin_password = var.vm_pass
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.interface.id]
  tags = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = var.os_sku
    version   = var.os_version
  }
}

resource "azurerm_virtual_machine_extension" "la_workspace" {
    name = azurerm_linux_virtual_machine.linux_vm.name
    virtual_machine_id = azurerm_linux_virtual_machine.linux_vm.id
    publisher = "Microsoft.EnterpriseCloud.Monitoring"
    type = "OMSAgentforLinux"
    type_handler_version = var.la_agent_version
    auto_upgrade_minor_version = "true"

    settings = <<SETTINGS
        {
            "workspaceId": "${var.la_workspace_id}"
        }
    SETTINGS

       protected_settings = <<PROTECTED_SETTINGS
   {
      "workspaceKey": "${var.la_primary_shared_key}"
   }
PROTECTED_SETTINGS
}
