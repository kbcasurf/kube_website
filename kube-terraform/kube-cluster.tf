terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.0.0"
    }
      kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "oci" {
  region = var.region
}

resource "kubernetes_namespace" "free_namespace" {
  metadata {
    name = "kube-ns"
  }
}

resource "kubernetes_deployment" "website_kube" {
  metadata {
    name = "website-kube"
    labels = {
      app = "website-kube"
    }
    namespace = kubernetes_namespace.free_namespace.id
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "website-kube"
      }
    }

    template {
      metadata {
        labels = {
          app = "website-kube"
        }
      }

      spec {
        image_pull_secrets {
          name = "oci-registry-secret"
        }
        container {
          image = "vcp.ocir.io/axtfvxixy3a6/aiservers/website_kube:v3"
          name  = "website-kube"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "website_kube_service" {
  metadata {
    name      = "website-kube-service"
    namespace = kubernetes_namespace.free_namespace.id
  }
  spec {
    selector = {
      app = "website-kube"
    }
    port {
      port        = 80
      target_port = 80
      node_port   = 31600
    }

    type = "NodePort"
  }
}

data "oci_containerengine_node_pool" "free_kube_np" {
  node_pool_id = var.node_pool_id
}

locals {
  active_nodes = [for node in data.oci_containerengine_node_pool.free_kube_np.nodes : node if node.state == "ACTIVE"]
}

resource "oci_network_load_balancer_network_load_balancer" "free_nlb" {
  compartment_id = var.compartment_id
  display_name   = "kube-nlb"
  subnet_id      = var.public_subnet_id

  is_private                     = false
  is_preserve_source_destination = false
}

resource "oci_network_load_balancer_backend_set" "free_nlb_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = 10256
  }
  name                     = "kube-backend-set"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.free_nlb.id
  policy                   = "FIVE_TUPLE"

  is_preserve_source = false
}

resource "oci_network_load_balancer_backend" "free_nlb_backend" {
  count                    = length(local.active_nodes)
  backend_set_name         = oci_network_load_balancer_backend_set.free_nlb_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.free_nlb.id
  port                     = 31600
  target_id                = local.active_nodes[count.index].id
}

resource "oci_network_load_balancer_listener" "free_nlb_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.free_nlb_backend_set.name
  name                     = "kube-nlb-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.free_nlb.id
  port                     = "80"
  protocol                 = "TCP"
}