# !/bin/bash
# 建立 ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name ${PREFIX}-alb \
  --subnets $PUBLIC_SUBNET_1 $PUBLIC_SUBNET_2 \
  --security-groups $ALB_SG \
  --region $AWS_REGION \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

echo "已建立 ALB: ${ALB_ARN}"

# 建立 Target groups
TG_ARN=$(aws elbv2 create-target-group \
  --name ${PREFIX}-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-protocol HTTP \
  --health-check-path / \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 5 \
  --region $AWS_REGION \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "已建立目標群組: ${TG_ARN}"

# 建立 HTTP 監聽器
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN \
  --region $AWS_REGION \
  --query 'Listeners[0].ListenerArn' \
  --output text)

echo "已建立監聽器: ${LISTENER_ARN}"