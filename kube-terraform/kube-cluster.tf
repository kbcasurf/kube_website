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

data "oci_core_images" "latest_image" {
  compartment_id = var.compartment_id
  operating_system = "Oracle Linux"
  operating_system_version = "8"
  filter {
    name   = "display_name"
    values = ["^.*aarch64-.*$"]
    regex = true
  }
}

resource "oci_containerengine_node_pool" "kube_node_pool" {
  cluster_id         = oci_containerengine_cluster.kube_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = "v1.31.1"
  name               = "kube-node-pool"

  node_config_details {
    dynamic placement_configs {
      for_each = local.azs
      content {
        availability_domain = placement_configs.value
        subnet_id           = oci_core_subnet.vcn_private_subnet.id

      }
    }
    size = 4

  }
  node_shape = "VM.Standard.A1.Flex"

  node_shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }

  node_source_details {
    image_id    = data.oci_core_images.latest_image.images.0.id
    source_type = "image"
  }

  initial_node_labels {
    key   = "name"
    value = "kube-cluster"
  }

  ssh_public_key = var.ssh_public_key
}

resource "oci_artifacts_container_repository" "docker_repository" {
  compartment_id = var.compartment_id
  display_name   = "kube-website"

  is_immutable = false
  is_public    = false
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

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}
locals {
  # Gather a list of availability domains for use in configuring placement_configs
  azs = data.oci_identity_availability_domains.ads.availability_domains[*].name
}