resource "aws_ebs_volume" "awsvolume" {
  availability_zone = "${var.region}a"
  size              = 30
  encrypted         = "false"

  tags = {
    Name = "EBS-Jenkins-Instance"
  }
}
resource "aws_volume_attachment" "ebs_att" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.awsvolume.id
  instance_id  = aws_instance.jenkins-instance.id
  skip_destroy = "true"
}