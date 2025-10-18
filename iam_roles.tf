# iam_roles.tf - IAM roles and instance profile for EC2

# IAM Role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name               = "WebAppEC2Role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(
    var.common_tags,
    {
      Name = "WebApp EC2 Role"
    }
  )
}

# Trust policy - allows EC2 to assume this role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Instance profile to attach role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "WebAppEC2Profile-${var.environment}"
  role = aws_iam_role.ec2_role.name

  tags = merge(
    var.common_tags,
    {
      Name = "WebApp EC2 Instance Profile"
    }
  )
}

