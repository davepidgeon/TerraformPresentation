#! /bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
echo "<img src=""https://media.giphy.com/media/Sg86rhq4G3vqM/giphy.gif"" /><h1 style=""font-family:georgia"">Our first Terraform server :)</h1>" | sudo tee /var/www/html/index.html