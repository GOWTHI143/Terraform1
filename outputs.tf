output "vpc-id" {
  value = aws_vpc.VPC.id
}
output "igw-id" {
  value = aws_internet_gateway.igw.id
}
output "SUBNT-id" {
  value = aws_subnet.SUBNT.id
}
output "RT-id" {
  value = aws_route_table.RT.id
}
output "sg-id" {
  value = aws_security_group.sg.id
}
output "subnt-az" {
  value = aws_subnet.SUBNT.availability_zone  
}
output "pub-ip" {
  value = aws_instance.AMI.public_ip
}
output "prv-ip" {
  value = aws_instance.AMI.private_ip
}
output "instance-id" {
  value = aws_instance.AMI.id
}
output "ami-id" {
  value = aws_ami_from_instance.AMI-ec2.id
}
output "Lau_Tmp_id" {
  value = aws_launch_template.Lau_Tmp.id
}
output "ASG-id" {
  value = aws_autoscaling_group.ASG.id
}
output "TG-arn" {
  value = aws_lb_target_group.For-lb.id  
}
output "LB-arn" {
  value = aws_lb.LB-TF.arn
}