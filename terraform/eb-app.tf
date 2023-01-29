resource "aws_elastic_beanstalk_application" "x-ray-app" {
  name = "X-Ray-Test-App"
}


# Instance Profile
resource "aws_iam_instance_profile" "x-ray-instance-profile" {
  name = "x_ray_app_profile"
  role = aws_iam_role.app_role.name
}

# Roles
data "aws_iam_policy_document" "xray_policy" {
  statement {
    effect = "Allow"
    actions = [ "xray:*" ]
    resources = ["*"]
  }
}


resource "aws_iam_role" "app_role" {
  name = "x_ray_app_role"
  path = "/"

  assume_role_policy = <<EOF
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
    managed_policy_arns = [ 
        "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService" ,
        "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker",
        "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
    ]

    inline_policy {
      name = "x-ray-access"
      policy = data.aws_iam_policy_document.xray_policy.json
    }
}


 
# Create elastic beanstalk Environment
 
resource "aws_elastic_beanstalk_environment" "env" {
  name                = "Test-env"
  application         = aws_elastic_beanstalk_application.x-ray-app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.3 running Docker"
  tier                = "WebServer"
 
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = module.vpc.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     =  "True"
  }
 
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", module.vpc.public_subnets)
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", module.vpc.public_subnets)
  }

  setting {
    namespace = "aws:elb:listener:80"
    name = "ListenerProtocol"
    value = "HTTP"
  } 

  setting {
    namespace = "aws:elb:listener:80"
    name = "InstanceProtocol"
    value = "HTTP"
  } 

  setting {
    namespace = "aws:elb:listener:80"
    name = "InstancePort"
    value = "80"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     =  aws_iam_instance_profile.x-ray-instance-profile.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
  
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internet facing"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = 1
  }
  
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = 1
  }

  setting {
     namespace = "aws:elasticbeanstalk:application:environment"
     name = "DB_HOST"
     value = aws_db_instance.education.address
  }

  setting {
     namespace = "aws:elasticbeanstalk:application:environment"
     name = "DB_PORT"
     value = aws_db_instance.education.port
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "DB_NAME"
    value = aws_db_instance.education.db_name
  }
 
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "DB_USERNAME"
    value = aws_db_instance.education.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "DB_PASSWORD"
    value = aws_db_instance.education.password
  }

}
