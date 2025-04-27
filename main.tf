# Définition de l'instance EC2 Ubuntu
resource "aws_instance" "ec2-ubuntu" {
  key_name                    = "key"                                      # Nom de la clé SSH utilisée pour se connecter
  instance_type               = "t2.micro"                                 # Type d'instance (petit modèle gratuit/économique)
  ami                         = "ami-084568db4383264d4"                    # ID de l'AMI Ubuntu utilisée
  associate_public_ip_address = true                                       # Associer une IP publique directement à l'instance
  vpc_security_group_ids      = [aws_security_group.ec2-security-group.id] # ID du Security Group associé
  subnet_id                   = aws_subnet.main.id                         # ID du sous-réseau dans lequel déployer l'instance

  tags = {
    Name = var.ec2-name # Attribuer un tag "Name" à l'instance
  }

  # Provisioning automatique de l'instance après création
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",           # Mise à jour des paquets
      "sudo apt install -y nginx", # Installation de Nginx
      "sudo systemctl start nginx" # Démarrage de Nginx
    ]

    # Connexion SSH pour le provisioner
    connection {
      type        = "ssh"
      user        = "ubuntu"          # Utilisateur par défaut sur Ubuntu Cloud AMI
      private_key = file("./key.pem") # Utilisation de la clé privée
      host        = self.public_ip    # Connexion via l'adresse IP publique
    }
  }

  # Définition du disque système (root)
  root_block_device {
    volume_size           = var.size # Taille du disque (venant d'une variable)
    volume_type           = "gp2"    # Type de volume EBS (standard SSD)
    delete_on_termination = true     # Suppression automatique du volume à la fin de l'instance
    tags = {
      Name = var.volume # Tag du volume
    }
  }
}

# Création du Security Group associé à l'EC2
resource "aws_security_group" "ec2-security-group" {
  vpc_id = aws_vpc.ec2-vpc.id # ID du VPC associé

  # Autoriser l'accès HTTPS depuis n'importe où
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Autoriser l'accès HTTP depuis n'importe où
  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Autoriser l'accès SSH depuis n'importe où
  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Autoriser tout le trafic sortant
  egress {
    description = "allow all traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = -1 # -1 = tous les protocoles
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allocation d'une Elastic IP (EIP) à l'instance EC2
resource "aws_eip" "ec2_eip" {
  instance = aws_instance.ec2-ubuntu.id

  provisioner "local-exec" {
    command = "echo PUBLIC IP: ${self.public_ip} > infos_ec2.txt" # Enregistrer l'IP publique dans un fichier local
  }
}

# Création d'un VPC personnalisé
resource "aws_vpc" "ec2-vpc" {
  cidr_block = "192.168.0.0/16" # Plage d'adresses privée du VPC
}

# Création d'un sous-réseau (subnet) dans le VPC
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.ec2-vpc.id
  cidr_block = "192.168.55.0/24" # Sous-réseau spécifique

  tags = {
    Name = "Main-subnet" # Tag du subnet
  }
}

# Création d'une Internet Gateway pour permettre la sortie vers Internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ec2-vpc.id

  tags = {
    Name = "igw" # Tag de l'Internet Gateway
  }
}

# Création d'une table de routage
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.ec2-vpc.id

  # Définir la route pour tout le trafic vers l'Internet Gateway
  route {
    cidr_block = "0.0.0.0/0" # Tout le trafic sortant
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Association de la table de routage au sous-réseau
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rtb.id
}
