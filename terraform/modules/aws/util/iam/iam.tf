#--------------------------------------------------------------
# This module creates all IAM resources
#--------------------------------------------------------------


resource "aws_iam_role" "openshift" {
  name                  = "openshift-instance-role"
  assume_role_policy    = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "openshift" {
  name  = "openshift-instance-profile"
  role  = "${aws_iam_role.openshift.name}"
}

resource "aws_iam_user" "openshift-aws-user" {
  name = "openshift-aws-user"
  path = "/"
}

resource "aws_iam_user_policy" "openshift-aws-user" {
  name = "openshift-aws-user-policy"
  user = "${aws_iam_user.openshift-aws-user.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "openshift-aws-user" {
  user    = "${aws_iam_user.openshift-aws-user.name}"
}

output "instance_profile_id" { value = "${aws_iam_instance_profile.openshift.id}" }
output "iam_access_key" { value = "${aws_iam_access_key.openshift-aws-user.id}" }
output "iam_secret_key" { value = "${aws_iam_access_key.openshift-aws-user.secret}" }
