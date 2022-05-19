resource "null_resource" "admin_user" {

  provisioner "local-exec" {
   when = "create"
    # interpreter = ["/bin/bash"]
    command = "./${path.module}/scripts/remove-kubeadmin.sh ${var.cluster_id} ${var.user} ${var.password} ${var.ssl_ready}"
  }
  
}