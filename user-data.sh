#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<h1>Welcome to My Scalable Forum Application</h1>" | sudo tee /var/www/html/index.html
