output "depend_on" {
  value = "${join(",", null_resource.admin_user.*.id)}"
}