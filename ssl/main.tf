

resource "null_resource" "ssl" {

  provisioner "local-exec" {
    when = "create"
    # interpreter = ["/bin/bash"]

    command = "./ssl/scripts/ssl.sh ${var.cluster_id} ${var.apikey} ${var.base_domain} ${var.secret_group_id} ${var.ca} ${var.service_url} ${var.master_ready}"
    
  }
  
}