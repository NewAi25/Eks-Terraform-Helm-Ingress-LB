$ErrorActionPreference = "Stop"

# -------- Config --------
$REGION  = "ap-south-1"
$CLUSTER = "my-eks-cluster"

$ROOT   = $PSScriptRoot
$INFRA  = Join-Path $ROOT "infra"
$ADDONS = Join-Path $ROOT "addons"

# Optional manifests at repo root
$NginxLbYaml    = Join-Path $ROOT "nginx-lb.yaml"
$DemoIngressYaml = Join-Path $ROOT "demo-ingress.yaml"

function Assert-DirHasTfFiles {
  param([string]$Path, [string]$Name)
  if (!(Test-Path $Path)) { throw "$Name folder not found: $Path" }
  $tfs = Get-ChildItem -Path $Path -Filter *.tf -ErrorAction SilentlyContinue
  if ($tfs.Count -eq 0) { throw "$Name has no .tf files: $Path" }
}

function Eks-ClusterExists {
  param([string]$Region, [string]$ClusterName)
  try { aws eks describe-cluster --region $Region --name $ClusterName | Out-Null; return $true }
  catch { return $false }
}

function Assert-KubectlWorks {
  kubectl get nodes -o wide
  if ($LASTEXITCODE -ne 0) { throw "kubectl cannot access the cluster. Stopping." }
}

Write-Host "=== Pre-check: tools ==="
aws --version | Out-Host
kubectl version --client | Out-Host
terraform version | Out-Host

Write-Host "=== Pre-check: AWS identity ==="
aws sts get-caller-identity | Out-Host

Write-Host "=== Pre-check: repo structure ==="
Assert-DirHasTfFiles -Path $INFRA  -Name "INFRA"
Assert-DirHasTfFiles -Path $ADDONS -Name "ADDONS"

# -------- Phase A: INFRA --------
Write-Host "=== Phase A: INFRA (VPC + EKS) ==="
terraform -chdir=$INFRA init
terraform -chdir=$INFRA validate
terraform -chdir=$INFRA apply -auto-approve

Write-Host "=== Verify EKS cluster exists (hard gate) ==="
if (-not (Eks-ClusterExists -Region $REGION -ClusterName $CLUSTER)) {
  throw "EKS cluster '$CLUSTER' not found in region '$REGION'."
}

Write-Host "=== Update kubeconfig ==="
aws eks update-kubeconfig --region $REGION --name $CLUSTER | Out-Host

Write-Host "=== Verify cluster access ==="
Assert-KubectlWorks

# -------- Phase B: ADDONS --------
Write-Host "=== Phase B: ADDONS (Ingress + LoadBalancer test) ==="
terraform -chdir=$ADDONS init
terraform -chdir=$ADDONS validate
terraform -chdir=$ADDONS apply -auto-approve

Write-Host "=== Verify ingress-nginx service (should be LoadBalancer) ==="
kubectl get svc -n ingress-nginx

# -------- Optional: apply root YAMLs if present --------
if (Test-Path $NginxLbYaml) {
  Write-Host "=== Apply nginx-lb.yaml (optional) ==="
  kubectl apply -f $NginxLbYaml
  kubectl get svc -n default
}

if (Test-Path $DemoIngressYaml) {
  Write-Host "=== Apply demo-ingress.yaml (optional) ==="
  kubectl apply -f $DemoIngressYaml
  kubectl get ingress -A
}

Write-Host "=== Done ✅ ==="