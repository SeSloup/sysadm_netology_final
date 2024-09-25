#https://github.com/yandex-cloud-examples/yc-website-high-availability-with-alb/blob/main/application-load-balancer-website.tf

# Объявление переменных для конфиденциальных параметров
/*
variable "dns_zone" {
  type      = string
}

variable "domain" {
  type      = string
}
*/

# Добавление прочих переменных

locals {
  sa_name = "sa"
}

# Настройка провайдера

resource "yandex_iam_service_account" "sa" {
  name = local.sa_name
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}


/*resource "yandex_vpc_subnet" "subnet-3" {
  name           = local.subnet_name3
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.3.0/24"]
}
*/

resource "yandex_vpc_security_group" "alb-sg" {
  folder_id = var.folder_id
  name       = "alb-sg"
  network_id = yandex_vpc_network.my-vpc.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  /*  ingress {
    protocol       = "TCP"
    description    = "ext-https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }
*/

  ingress {
    protocol          = "TCP"
    description       = "healthchecks"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }
}

resource "yandex_vpc_security_group" "alb-vm-sg" {
  folder_id = var.folder_id
  name       = "alb-vm-sg"
  network_id = yandex_vpc_network.my-vpc.id

  egress {
    protocol          = "TCP"
    description       = "balancer"
    security_group_id = yandex_vpc_security_group.alb-sg.id
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "balancer"
    security_group_id = yandex_vpc_security_group.alb-sg.id
    port              = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
}
/*
resource "yandex_compute_image" "lemp" {
  source_family = "lemp"
}
*/
resource "yandex_compute_instance_group" "alb-vm-group" {
  name               = "alb-vm-group"
  service_account_id = yandex_iam_service_account.sa.id
  instance_template {
        #    platform_id        = "standard-v2"
    service_account_id = yandex_iam_service_account.sa.id
    name = "vm-nginx-{instance.index}"
 
    resources {
      cores         = var.cores
      memory        = var.memory
      core_fraction = var.core_fraction
    }

    boot_disk {
      initialize_params {
        image_id = var.image_id //id образа (из стандартных настроек (см. скриншот))
        //name = "Ubuntu-yandexcloud-netology"
        size = var.size
      }
    }

    network_interface {
      network_id = yandex_vpc_network.my-vpc.id
      subnet_ids = [yandex_vpc_subnet.private-subnet1.id, yandex_vpc_subnet.private-subnet2.id] #,yandex_vpc_subnet.subnet-3.id]
      //nat                = true
      security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id, yandex_vpc_security_group.alb-vm-sg.id]
    }

    metadata = {
      user-data = file("${path.module}/cloud-config")
    }

    scheduling_policy {
      preemptible = true
    }

  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    zones = ["ru-central1-a", "ru-central1-b"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
    max_deleting    = 2
  }

  application_load_balancer {
    target_group_name = "alb-tg"
  }
}

//
resource "yandex_alb_backend_group" "alb-bg" {
  folder_id = var.folder_id
  name = "alb-bg"

  http_backend {
    name             = "backend-1"
    port             = 80
    target_group_ids = [yandex_compute_instance_group.alb-vm-group.application_load_balancer.0.target_group_id]
    healthcheck {
      timeout          = "10s"
      interval         = "2s"
      healthcheck_port = 80
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "alb-router" {
  
  name = "alb-router"
}

resource "yandex_alb_virtual_host" "alb-host" {
  name           = "alb-host"
  http_router_id = yandex_alb_http_router.alb-router.id
  //authority      = [var.domain, "www.${var.domain}"]
  route {
    name = "route-1"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.alb-bg.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "alb-1" {
  name               = "alb-1"
  network_id         = yandex_vpc_network.my-vpc.id
  security_group_ids = [yandex_vpc_security_group.alb-sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.private-subnet1.id
    }

    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.private-subnet2.id
    }
    /*
    location {
      zone_id   = "ru-central1-c"
      subnet_id = yandex_vpc_subnet.subnet-3.id
    }
*/
  }

  listener {
    name = "alb-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.alb-router.id
      }
    }
  }
}

/*
resource "yandex_dns_zone" "alb-zone" {
  name        = "alb-zone"
  description = "Public zone"
  zone        = "${var.domain}."
  public      = true
}

resource "yandex_dns_recordset" "rs-1" {
  zone_id = yandex_dns_zone.alb-zone.id
  name    = "${var.domain}."
  ttl     = 600
  type    = "A"
  data    = [yandex_alb_load_balancer.alb-1.listener[0].endpoint[0].address[0].external_ipv4_address[0].address]
}

resource "yandex_dns_recordset" "rs-2" {
  zone_id = yandex_dns_zone.alb-zone.id
  name    = "www"
  ttl     = 600
  type    = "CNAME"
  data    = [ var.domain ]
}
*/