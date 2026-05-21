# EKS + Terraform + Helm + Ingress LB

End-to-end provisioning of an **Amazon EKS** cluster with **Terraform**, application deployment via **Helm**, and traffic routing through an **NGINX Ingress** controller backed by an AWS load balancer.

## 🚀 What this project does

Provisions a production-style EKS environment in a single workflow:

1. Networking, IAM, and the EKS control plane are created with Terraform.
2. 2. Cluster add-ons (NGINX ingress controller, AWS Load Balancer Controller, etc.) are installed via Helm.
   3. 3. A demo workload is exposed through an `Ingress` resource fronted by an AWS LB.
     
      4. ## 🧩 Architecture
     
      5. `Terraform (infra/, iam/)` → `EKS Cluster` → `Helm add-ons (addons/)` → `NGINX Ingress + AWS LB` → `Demo app`
     
      6. ## 📁 Repository layout
     
      7. | Path | Purpose |
      8. |---|---|
      9. | `infra/` | Terraform modules for VPC, EKS, node groups |
      10. | `iam/` | IAM roles and policies for the cluster and controllers |
      11. | `addons/` | Helm values / charts for ingress and supporting add-ons |
      12. | `demo-ingress.yaml` | Sample Ingress resource for testing |
      13. | `nginx-lb.yaml` | NGINX LoadBalancer service manifest |
      14. | `install-prereqs.ps1` | Installs CLI prerequisites (Terraform, kubectl, helm, aws-cli) |
      15. | `deploy.ps1` | One-shot deploy script |
     
      16. ## ✅ Prerequisites
     
      17. - An AWS account with permissions to create EKS, VPC, IAM, and ELB resources
          - - AWS CLI configured (`aws configure`)
            - - Terraform >= 1.5
              - - kubectl and Helm 3 installed (run `install-prereqs.ps1` on Windows)
               
                - ## ⚡ Quick start
               
                - ```powershell
                  # 1. Install required CLIs (Windows)
                  ./install-prereqs.ps1

                  # 2. Provision infrastructure and deploy add-ons
                  ./deploy.ps1

                  # 3. Verify the cluster and ingress
                  kubectl get nodes
                  kubectl get ingress
                  ```

                  ## 🧹 Tear down

                  ```bash
                  cd infra
                  terraform destroy
                  ```

                  ## 📝 Notes

                  This project is meant as a reference / learning template for EKS + Terraform + Helm workflows. Review all Terraform variables and IAM policies before using in a real environment.

                  ## 📄 License

                  MIT
                  
