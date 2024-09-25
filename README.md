## Usage

1. VPC Creation: Navigate to 'vpc.tf`, configure AWS Terraform provider, and define VPC parameters.

2. EKS Cluster Provisioning: Head to 'eks.tf`, configure EKS cluster parameters, and run Terraform commands.

3. IAM User & Role Setup: Refer to `iam.tf` for creating IAM policies, roles, users, and associations.

4. Cluster Autoscaler Deployment: Explore `autoscaler-iam.tf` for IAM role creation, `autoscaler-manifest.tf` for deploying Cluster Autoscaler.

5. AWS Load Balancer Controller Deployment: Configure Helm provider in `helm-provider.tf`, create IAM role in `terraform/helm-load-balancer-controller.tf`, and deploy the controller using Helm in `terraform/helm-load-balancer-controller.tf`.

6. Testing with Nginx Deployment and Echo Server: Apply the provided Kubernetes manifests in `nginx.yaml` for testing autoscaling and load balancing.

7. Verify Setup: Ensure all components are running with `kubectl get pods -n kube-system`.

8. Explore Further: Feel free to customize configurations based on your specific requirements.



Main commands code$
  init          Prepare your working directory for other commands
  validate      Check whether the configuration is valid
  plan          Show changes required by the current configuration
  apply         Create or update infrastructure


# Go to code folder
cd /home/ubuntu/sloved_assesment_vpc_eks_k8s_monitoring
terraform init
terraform validate
terraform plan
terraform apply
terraform show

# Once completed, update the Kubernetes context to connect to the cluster:

aws eks update-kubeconfig --name camlin-eks  --region us-east-1

# Verify successful access to the EKS cluster
kubectl get nodes
# see pods and service running in default
kubectl get pods
kubectl get svc

# list namespaces to look services
kubectl get namespaces
kubectl get pods -n kube-node-lease
kubectl get pods -n kube-public
# Verify that the autoscaler is running
kubectl get pods -n kube-system
# Apply the deployment
kubectl apply -f nginx.yaml

# Create an Echo server deployment with Ingress
kubectl apply -f echoserver.yaml
kubectl get ingress

## Note this project is lot more to cover
for CI/CD

Github action we can add apply command what ever services added on and merge

# Monitoring with helm on EKS first install dependency
- Dependency install on server commands
  * sudo apt update
  * curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  * helm version
  * helm repo add stable https://charts.helm.sh/stable
  * helm repo update

# 1. Add Helm Repositories for Prometheus and Grafana
- helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
- helm repo add grafana https://grafana.github.io/helm-charts
- helm repo update

# Install Prometheus with Helm
- helm install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace
- kubectl get all -n monitoring

# Accessing Prometheus
- kubectl port-forward -n monitoring deploy/prometheus-server 9090

# Install Grafana with Helm
- helm install grafana grafana/grafana --namespace monitoring
- kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Accessing Grafana
- kubectl port-forward -n monitoring svc/grafana 3000:80

##  Install ArgoCD in Kubernetes
- kubectl create namespace argocd
- kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
- kubectl get pods -n argocd

# Access ArgoCD Server
- kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get the Initial Admin Password:
- kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode; echo
- argocd login <ARGOCD_SERVER>


## Clenup everything one by one one you are done testing
kubectl delete namespace argocd
terraform destroy
