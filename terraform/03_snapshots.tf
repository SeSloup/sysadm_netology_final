resource "yandex_compute_snapshot_schedule" "snapshotschedulesevendays" {
  folder_id = var.folder_id
  name           = "snapshotschedulesevendays"

  schedule_policy {
	expression = "25 2 * * *"
  }

  snapshot_count = 7

  snapshot_spec {
	  description = "Every day per week"
	  labels = {
	    snapshot-label = "snapshot_schedule_seven_days_label"
	  }
  }
  
  count = var.count_nginx

  disk_ids = [
          yandex_compute_instance.nat-instance.boot_disk[0].disk_id          ,
          yandex_compute_instance.vm-kibana.boot_disk[0].disk_id,
          yandex_compute_instance.vm-elk.boot_disk[0].disk_id,
          yandex_compute_instance.vm-zabbix.boot_disk[0].disk_id,
          #yandex_compute_instance_group.alb-vm-group.instance_template[0].boot_disk[0].disk_id
          
  ]
}
