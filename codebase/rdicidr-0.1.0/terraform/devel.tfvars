aws_region        = "us-east-1"
app_name          = "rdicidr"
environment       = "devel"
desired_count     = 1
container_port    = 80
health_check_path = "/health"
# container_image is injected by CI: -var container_image=<ecr>:<git-sha>
