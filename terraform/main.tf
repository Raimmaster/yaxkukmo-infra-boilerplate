module "web-app" {
  source             = "./web-app"
  vpc                = module.vpc.vpc_id
  availability_zones = module.vpc.azs
  private_subnets    = module.vpc.private_subnets
  public_subnets     = module.vpc.public_subnets
  domain             = var.domain
  jumper_ip          = module.jumper_vpn.private_ip
  public_key         = var.public_key
}

module "jumper_vpn" {
  source          = "./jumper-vpn"
  vpc             = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  home_ip         = var.home_ip
}