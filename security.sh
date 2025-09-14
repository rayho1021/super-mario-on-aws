# !/bin/bash

# 建 ALB security group
ALB_SG=$(aws ec2 create-security-group \
  --group-name ${PREFIX}-alb-sg \
  --description "Security group for ALB" \
  --vpc-id $VPC_ID \
  --region $AWS_REGION \
  --query 'GroupId' \
  --output text)

aws ec2 create-tags \
  --resources $ALB_SG \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-alb-sg

# 允許 HTTP 流量進入 ALB
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION

echo "已建立 ALB 安全群組: ${ALB_SG}"

# 建立 ECS SG
ECS_SG=$(aws ec2 create-security-group \
  --group-name ${PREFIX}-ecs-sg \
  --description "Security group for ECS tasks" \
  --vpc-id $VPC_ID \
  --region $AWS_REGION \
  --query 'GroupId' \
  --output text)

aws ec2 create-tags \
  --resources $ECS_SG \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-ecs-sg

# 允許從 ALB 的流量進入 ECS 任務
aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG \
  --protocol tcp \
  --port 8080 \
  --source-group $ALB_SG \
  --region $AWS_REGION

echo "已建立 ECS SG: ${ECS_SG}"