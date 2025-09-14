#!/bin/bash
# 獲取 ALB DNS 名稱
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --region $AWS_REGION \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "===================================================="
echo "請稍候幾分鐘以讓服務正常啟動..."
echo "歡迎訪問以下 URL 來玩 Super Mario 遊戲："
echo "http://${ALB_DNS}"
echo "===================================================="