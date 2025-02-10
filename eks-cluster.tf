module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.19.1"

  cluster_name = local.cluster_name

  vpc_id = module.vpc.vpc_id

  # Make sure the control plane is in the main AWS Region, not Wavelength
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name           = "node-group-1"
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

    }

    two = {
      name           = "node-group-2"
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1

    }
  }
}
