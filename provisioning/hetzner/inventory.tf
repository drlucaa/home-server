# --- ANSIBLE INVENTORY ---
resource "local_file" "ansible_inventory" {
  content = yamlencode({
    k3s_cluster = {
      children = {
        # Control Plane Nodes (Mapped to 'server')
        server = {
          hosts = {
            for i, server in hcloud_server.control_plane :
            server.name => {
              ansible_host = server.ipv4_address
              ansible_user = "admin"
              k3s_node_ip  = "10.0.1.${10 + i}"
            }
          }
        }
        # Worker Nodes (Mapped to 'agent')
        agent = {
          hosts = {
            for i, server in hcloud_server.worker :
            server.name => {
              ansible_host = server.ipv4_address
              ansible_user = "admin"
              k3s_node_ip  = "10.0.1.${100 + i}"
            }
          }
        }
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}
