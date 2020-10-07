#! /bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
echo "<img src=""https://media.giphy.com/media/JJGUejl0pLcRy/giphy.gif"" width=""480"" height=""394"" /><h1 style=""font-family:georgia"">Our second Terraform server :)</h1>" | sudo tee /var/www/html/index.html