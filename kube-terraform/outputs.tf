output "free_load_balancer_public_ip" {
    value = [for ip in oci_network_load_balancer_network_load_balancer.free_nlb.ip_addresses : ip if ip.is_public == true]
}

output "node_pool_id" {
  value = oci_containerengine_node_pool.kube_node_pool.id
}