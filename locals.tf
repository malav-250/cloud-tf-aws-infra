#local values for computed configurations
locals {
  # Determine which AZs to use
  all_available_azs = data.aws_availability_zones.available.names

  #if specific AZs provided, use those; otherwise use first N available AZs
  selected_azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(
    local.all_available_azs,
    0,
    min(var.az_count, length(local.all_available_azs))
  )

  # Number of selected AZs
  az_count = length(local.selected_azs)

  # Create mappings for subnet to AZ distribution
  # This cycles through AZs if subnet count > AZ count
  public_subnet_az_mapping = {
    for i in range(var.public_subnet_count) : i => local.selected_azs[i % local.az_count]
  }

  private_subnet_az_mapping = {
    for i in range(var.private_subnet_count) : i => local.selected_azs[i % local.az_count]
  }

  # Count subnets per AZ for better visibility
  public_subnets_per_az = {
    for az in local.selected_azs : az => length([
      for idx, mapped_az in local.public_subnet_az_mapping : idx if mapped_az == az
    ])
  }

  private_subnets_per_az = {
    for az in local.selected_azs : az => length([
      for idx, mapped_az in local.private_subnet_az_mapping : idx if mapped_az == az
    ])
  }
}