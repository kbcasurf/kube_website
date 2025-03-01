# Website_kube

## Description
This repository contains the source code for the website developed for fun. The project utilizes basically HTML, Javascrips, CSS and docker images and is prepared to be deployed in a Kubernetes cluster on Oracle Cloud (OKE).

## Requirements
Before proceeding with the build and deployment, ensure you have installed:

- [Docker](https://docs.docker.com/get-docker/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/)
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
- Access to the configured OKE cluster on Oracle Cloud

## Build and Push Docker Image

1. Navigate to the project directory and build the Docker image:
   ```sh
   docker build -t <your-registry>/<your-repository>:latest .
   ```
2. Authenticate with Oracle Container Registry (if applicable):
   ```sh
   docker login <your-registry>
   ```
3. Push the image to the repository:
   ```sh
   docker push <your-registry>/<your-repository>:latest
   ```

## Connecting to the OKE Cluster

1. Authenticate with Oracle Cloud:
   ```sh
   oci session authenticate
   ```
2. Configure the Kubernetes context:
   ```sh
   oci ce cluster create-kubeconfig --cluster-id <CLUSTER_OCID> --file $HOME/.kube/config --region <YOUR_REGION> --token-version 2.0.0
   ```
3. Verify the connection:
   ```sh
   kubectl get nodes
   ```

## Deploying the Application
1. Apply the Kubernetes manifests:
   ```sh
   kubectl apply -f k8s/
   ```
2. Check the pods and services:
   ```sh
   kubectl get pods
   kubectl get svc
   ```
3. To follow the application logs:
   ```sh
   kubectl logs -f <pod-name>
   ```


## License
This project is licensed under the [MIT License](LICENSE).

