$ErrorActionPreference = "Stop"

Write-Host "=== Pre-check: AWS identity ==="
aws sts get-caller-identity | Out-Host

Write-Host "=== Phase A: INFRA (VPC + EKS) ==="
cd C:\eks-terraform\infra
terraform init
terraform validate
terraform apply -auto-approve

Write-Host "=== Update kubeconfig ==="
aws eks update-kubeconfig --region ap-south-1 --name my-eks-cluster

Write-Host "=== Verify cluster access ==="
kubectl get nodes -o wide

Write-Host "=== Phase B: ADDONS (Ingress + LoadBalancer test) ==="
cd C:\eks-terraform\addons
terraform init
terraform validate
terraform apply -auto-approve

Write-Host "=== Verify ingress-nginx service (should be LoadBalancer) ==="
kubectl get svc -n ingress-nginx

Write-Host "=== Verify test nginx LoadBalancer service ==="
kubectl get svc -n default