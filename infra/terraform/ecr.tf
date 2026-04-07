# ---------------------------------------------------------------------------
# ECR Repositories
# force_delete = true so terraform destroy can remove repos that contain images.
#
# Import commands:
#   terraform import aws_ecr_repository.backend zahir-backend
#   terraform import aws_ecr_repository.frontend zahir-frontend
# ---------------------------------------------------------------------------

resource "aws_ecr_repository" "backend" {
  name         = "zahir-backend"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = false
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_ecr_repository" "frontend" {
  name         = "zahir-frontend"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = false
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}
