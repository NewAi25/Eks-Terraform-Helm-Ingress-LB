############################################
# EKS (terraform-aws-modules/eks v20.x)
# Dynamic admin access (Option 2)
############################################

data "aws_caller_identity" "current" {}

locals {
  caller_arn = data.aws_caller_identity.current.arn

  # If Terraform runs via assumed role:
  # arn:aws:sts::<acct>:assumed-role/<role>/<session>
  # convert to:
  # arn:aws:iam::<acct>:role/<role>
  caller_principal_arn = (
    length(regexall("^arn:aws:sts::[0-9]{12}:assumed-role/", local.caller_arn)) > 0
    ? replace(
      local.caller_arn,
      "^arn:aws:sts::([0-9]{12}):assumed-role/([^/]+)/.*$",
      "arn:aws:iam::$1:role/$2"
    )
    : local.caller_arn
  )
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3a.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    }
  }

  ########################################################
  # ✅ AUTH FIX (v20.x): EKS Access Entries (dynamic)
  ########################################################

  # Use AWS API auth (Access Entries). Keeping ConfigMap auth too is fine.
  authentication_mode = "API_AND_CONFIG_MAP"

  # IMPORTANT: disable creator-admin to avoid duplicate access entry
  enable_cluster_creator_admin_permissions = false

  # Dynamic admin access for whoever runs Terraform (user or role).
  access_entries = {
    terraform_admin = {
      principal_arn = local.caller_principal_arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}