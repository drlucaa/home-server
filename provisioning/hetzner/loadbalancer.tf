resource "hcloud_load_balancer" "k3s" {
  name               = "k3s-lb"
  load_balancer_type = "lb11"
  location           = var.location
}

resource "hcloud_load_balancer_network" "k3s" {
  load_balancer_id = hcloud_load_balancer.k3s.id
  network_id       = hcloud_network.k3s.id
  ip               = var.load_balancer_private_ip
}

resource "hcloud_load_balancer_service" "kube_api" {
  load_balancer_id = hcloud_load_balancer.k3s.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "http" {
  load_balancer_id = hcloud_load_balancer.k3s.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 80

  health_check {
    protocol = "tcp"
    port     = 80
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "https" {
  load_balancer_id = hcloud_load_balancer.k3s.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 443

  health_check {
    protocol = "tcp"
    port     = 443
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_target" "agent" {
  count            = var.agent_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.k3s.id
  server_id        = hcloud_server.agent[count.index].id
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.k3s]
}

resource "hcloud_load_balancer_target" "server" {
  count            = var.server_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.k3s.id
  server_id        = hcloud_server.server[count.index].id
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.k3s]
}
