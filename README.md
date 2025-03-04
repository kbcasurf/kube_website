# Kubernetes cluster on Oracle Cloud OKE

The repository contains a Terraform script for creating a fully functioning
Kubernetes cluster on Oracle Cloud.

## Setup
1. Get the following data from your Oracle Cloud account
    * User OCID
    * Tenancy OCID
    * Compartment OCID
1. Open a terminal within the `oci-terraform` folder
1. Execute a `terraform init`
1. Execute a `terraform apply`
1. Create your Kubernetes configuration file using 
    ```bash
    $ oci ce cluster create-kubeconfig --cluster-id <cluster OCID> --file ~/.kube/config --region <region> --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT
    ```
1. Apply your K8S config for kubectl
    ```bash
    $ export KUBECONFIG=~/.kube/config
    ```
1. To verify cluster access, do a `kubectl get nodes`