#These are the only value that need to be changed on implementation
region                   = "us-west-1"
vpc_cidr                 = "10.0.0.0/16"
public_subnet_1          = "10.0.1.0/24"
public_subnet_2          = "10.0.2.0/24"
private_subnet_1         = "10.0.3.0/24"
private_subnet_2         = "10.0.4.0/24"
availibilty_zone_1       = "us-west-1b"
availibilty_zone_2       = "us-west-1c"
container_port           = 8080
# shared_config_files      = "C:/Users/mzc/.aws/config"           # Replace with path
# shared_credentials_files = "C:/Users/mzc/.aws/credentials"      # Replace with path
shared_config_files      = "C:/Users/BBoSSg/.aws/config"      # Replace with path
shared_credentials_files = "C:/Users/BBoSSg/.aws/credentials" # Replace with path
credential_profile       = "lsb-admin"                          # Replace with what you named your profile
domain_name              = "minzs.shop"                         # Replace with your domain name
ecs_service_name         = "prd_lsb_ecs_service"
ecs_cluster_name         = "prd_lsb_ecs_cluster"
