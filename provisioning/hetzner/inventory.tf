# --- ANSIBLE INVENTORY ---
resource "local_file" "ansible_inventory" {
  content = yamlencode({
    k3s_cluster = {
      children = {
        server = {
          hosts = {
            for i, server in hcloud_server.server :
            server.name => {
              ansible_host = server.ipv4_address
              ansible_user = "admin"
              k3s_node_ip  = tolist(server.network)[0].ip
            }
          }
        }
        agent = {
          hosts = {
            for i, server in hcloud_server.agent :
            server.name => {
              ansible_host = server.ipv4_address
              ansible_user = "admin"
              k3s_node_ip  = tolist(server.network)[0].ip
            }
          }
        }
      }
      vars = {
        api_endpoint          = hcloud_load_balancer_network.k3s.ip
        external_api_endpoint = hcloud_load_balancer.k3s.ipv4
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}
