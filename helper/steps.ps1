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

# Load example 2
Copy-Item $M2\* -Include "*.tf" -Destination $BuildFolder -Force -Confirm:$false

# Load example 3
Copy-Item $M3\* -Include "*.tf" -Destination $BuildFolder -Force -Confirm:$false