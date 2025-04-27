# Déclaration d'une variable Terraform appelée "size"
variable "size" {
  type        = number # Type attendu : un nombre
  description = "set aws instance rbs volume size"
  default     = 10 # Valeur par défaut : 10 Go
}

# Déclaration d'une variable Terraform appelée "volume"
variable "volume" {
  type        = string # Type attendu : une chaîne de caractères
  description = "set volume name"
  default     = "ec2-volume" # Valeur par défaut : "ec2-volume"
}

# Déclaration d'une variable Terraform appelée "ec2-name"
variable "ec2-name" {
  default = "ec2-ubuntu" # Valeur par défaut : "ec2-ubuntu" pour nommer l'instance EC2
}







