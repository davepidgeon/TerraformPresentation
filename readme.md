# Introduction
This is a simple example to deploy a two webservers and a load balancer in to an Azure subscription. The webservers will show different images, so you'll know when you're hitting each one.

# Getting Setup
1. Ensure you've got Terraform installed (full details: https://learn.hashicorp.com/tutorials/terraform/install-cli), if you're using Windows and Chocolatey:

    `choco install terraform`

2. Clone this repo
3. Now you're ready to go. You can either go step by step, installing a webserver first, then adding a load balancer and finally adding a second web server or you can skip to the end and deploy them all.

# Running the code
1. In the \helper folder there are a couple of scripts which will copy the files to the \build directory, just set the $Source directory to the root of where your code is.

2. Run the following code to copy all the required files in to the \build directory

````powershell
$Source = "C:\git\terraform-presentation"
$BuildFolder = Join-Path $Source "build"
$HelperFolder = Join-Path $Source "helper"
$M1 = Join-Path $Source "1-vm"
$M2 = Join-Path $Source "2-load-balancer"
$M3 = Join-Path $Source "3-web-farm"

# Delete anything in the build folder
Get-ChildItem $BuildFolder | Remove-Item -Force -Confirm:$false -Recurse

# Copy the helper files
Copy-Item $HelperFolder\* -Include "*.sh" -Destination $BuildFolder

# Load example 1
Copy-Item $M1\* -Include "*.tf" -Destination $BuildFolder -Force -Confirm:$false
````

3. Run `terraform init` to initialise Terraform
4. Authenticate to Azure (e.g. via the Azure CLI https://www.terraform.io/docs/providers/azurerm/guides/azure_cli.html)
5. Run `terraform plan`
6. Run `terraform apply` to deploy your first web server
7. To continue deploying the rest of the infrastruture you can run the `Copy-Item $M2\* -Include "*.tf" -Destination $BuildFolder -Force -Confirm:$false` commands to update the Terraform file with additional infrastructure and redeploy.