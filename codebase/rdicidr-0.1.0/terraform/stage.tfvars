aws_region        = "us-east-1"
app_name          = "rdicidr"
environment       = "stage"
desired_count     = 2
container_port    = 80
health_check_path = "/health"
# container_image is injected by CI: -var container_image=<ecr>:<git-sha>
