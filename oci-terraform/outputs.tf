output "kube_cluster_id" {
  value = oci_containerengine_cluster.kube_cluster.id
}

output "public_subnet_id" {
  value = oci_core_subnet.vcn_public_subnet.id
}