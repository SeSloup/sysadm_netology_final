variable "yandex_cloud_token" {
  type        = string
  description = "Данная переменная потребует ввести секретный токен в консоли при запуске terraform plan/apply"
}

variable "zones" {
  default     = ["ru-central1-b", "ru-central1-a"]
  type        = list(string)
  description = "Zones"
}

variable "cores" {
  description = "CPU Cores"
}

variable "memory" {
  description = "RAM"
}

variable "core_fraction" {
  description = "CPU % activity"
}

variable "size" {
  description = "HDD memory"
}

variable "image_id" {
  description = "id OS.iso"
}

variable "count_nginx" {
  description = "count of nginx vsrv"
}

variable "for_vars" {
}

variable "folder_id" {

}