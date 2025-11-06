# ========================================
# Scale Up Policy
# ========================================

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.environment}-scale-up-policy"
  scaling_adjustment     = var.scale_up_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.asg_cooldown
  autoscaling_group_name = aws_autoscaling_group.application.name
}

# ========================================
# Scale Down Policy
# ========================================

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.environment}-scale-down-policy"
  scaling_adjustment     = var.scale_down_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.asg_cooldown
  autoscaling_group_name = aws_autoscaling_group.application.name
}

# ========================================
# CloudWatch Alarm - High CPU (Scale Up)
# ========================================

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_up_cpu_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization and triggers scale up"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.application.name
  }

  tags = {
    Name        = "${var.environment}-high-cpu-alarm"
    Environment = var.environment
  }
}

# ========================================
# CloudWatch Alarm - Low CPU (Scale Down)
# ========================================

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.environment}-low-cpu-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_down_cpu_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization and triggers scale down"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.application.name
  }

  tags = {
    Name        = "${var.environment}-low-cpu-alarm"
    Environment = var.environment
  }
}