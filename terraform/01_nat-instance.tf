

# Добавление прочих переменных

locals {
  network_name     = "my-vpc"
  subnet_name1     = "public-subnet"
  subnet_name2     = "private-subnet1"
  sg_nat_name      = "nat-instance-sg"
  vm_test_name     = "test-vm"
  vm_nat_name      = "nat-instance"
  route_table_name = "nat-instance-route"
}


# Создание облачной сети

resource "yandex_vpc_network" "my-vpc" {
  folder_id = var.folder_id
  name = local.network_name
}

# Создание подсетей

resource "yandex_vpc_subnet" "public-subnet1" {
  folder_id = var.folder_id
  name           = "public-subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.1.0/24"]
  
}

# subnet для корректной работы nat в публичной области
resource "yandex_vpc_subnet" "public-subnet2" {
  folder_id = var.folder_id
  name           = "public-subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["10.10.10.0/24"]
  
}

resource "yandex_vpc_subnet" "private-subnet1" {
  folder_id = var.folder_id
  name           = local.subnet_name2
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.2.0/24"]
  route_table_id = yandex_vpc_route_table.nat-instance-route.id
}

# subnet для nginx из "ru-central1-b"
resource "yandex_vpc_subnet" "private-subnet2" {
  folder_id = var.folder_id
  name           = "private-subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.3.0/24"]
#  route_table_id = yandex_vpc_route_table.nat-instance-route.id
  route_table_id = yandex_vpc_route_table.rt.id
}


# Создание группы безопасности

resource "yandex_vpc_security_group" "nat-instance-sg" {
  name       = local.sg_nat_name
  network_id = yandex_vpc_network.my-vpc.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-https-zabbix"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 1111
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-https-kibana"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 2222
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-https-kibana"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9200
  }

/*    ingress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
*/
}

resource "yandex_vpc_security_group" "nat-instance-sg2" {
  name       = "nat-instance-sg2"
  network_id = yandex_vpc_network.my-vpc.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
/*
    ingress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
*/  
}

# Создание ВМ

//zone a

resource "yandex_compute_instance" "vm-zabbix" {
  folder_id = var.folder_id
  name     = "vm-zabbix"
  hostname = "vm-zabbix.ru-central1.internal"
  zone     = "ru-central1-b"
  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = var.core_fraction //использование процессора 20% (делимся ресурсами) - для экономии
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id //id образа (из стандартных настроек (см. скриншот))
      //name = "Ubuntu-yandexcloud-netology"
      size = var.size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet2.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
  }

  metadata = {
    user-data = file("${path.module}/cloud-config")
  }
}

resource "yandex_compute_instance" "vm-elk" {
  folder_id = var.folder_id
  name     = "vm-elk"
  hostname = "vm-elk.ru-central1.internal"
  zone     = "ru-central1-b"
  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = var.core_fraction //использование процессора 20% (делимся ресурсами) - для экономии
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id //id образа (из стандартных настроек (см. скриншот))
      //name = "Ubuntu-yandexcloud-netology"
      size = var.size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet2.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
  }

  metadata = {
    user-data = file("${path.module}/cloud-config")
  }
}

resource "yandex_compute_instance" "vm-kibana" {
  name     = "vm-kibana"
  hostname = "vm-kibana.ru-central1.internal"
  zone     = "ru-central1-b"
  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = var.core_fraction //использование процессора 20% (делимся ресурсами) - для экономии
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id //id образа (из стандартных настроек (см. скриншот))
      //name = "Ubuntu-yandexcloud-netology"
      size = var.size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet2.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
  }

  metadata = {
    user-data = file("${path.module}/cloud-config")
  }
}

/*//zone b
resource "yandex_compute_instance" "test-vm2" {
  name     = "test-vm2"
  hostname = "test-vm2.ru-central1.internal"
  zone     = "ru-central1-b"
  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = var.core_fraction //использование процессора 20% (делимся ресурсами) - для экономии
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id //id образа (из стандартных настроек (см. скриншот))
      //name = "Ubuntu-yandexcloud-netology"
      size = var.size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet2.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
  }

  metadata = {
    user-data = file("${path.module}/cloud-config")
  }
}
*/

# Создание ВМ NAT

resource "yandex_compute_instance" "nat-instance" {
  folder_id = var.folder_id
  name     = "nat-instance"
  hostname = "nat-instance.ru-central1.internal"
  zone     = "ru-central1-a"
  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = var.core_fraction //использование процессора 20% (делимся ресурсами) - для экономии
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id //id образа (из стандартных настроек (см. скриншот))
      //name = "Ubuntu-yandexcloud-netology"
      size = var.size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet1.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
    nat                = true
  }

  metadata = {
    user-data = file("${path.module}/cloud-config")
  }
}

# Создание таблицы маршрутизации и статического маршрута
//
resource "yandex_vpc_gateway" "nat_gateway" {
  folder_id      = var.folder_id
  name = "test-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  folder_id      = var.folder_id
  name       = "test-route-table"
  network_id = yandex_vpc_network.my-vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
//
resource "yandex_vpc_route_table" "nat-instance-route" {
  name       = "nat-instance-route"
  folder_id      = var.folder_id
  network_id = yandex_vpc_network.my-vpc.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    #next_hop_address   = yandex_compute_instance.nat-instance.network_interface.0.ip_address
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
