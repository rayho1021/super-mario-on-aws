# !/bin/bash
# 建立 ECS cluster
aws ecs create-cluster \
  --cluster-name ${PREFIX}-cluster \
  --region $AWS_REGION

echo "已建立 ECS 叢集: ${PREFIX}-cluster"

# 建立任務執行角色
cat > task-execution-role.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name ${PREFIX}-task-execution-role \
  --assume-role-policy-document file://task-execution-role.json

aws iam attach-role-policy \
  --role-name ${PREFIX}-task-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

echo "已建立任務執行角色: ${PREFIX}-task-execution-role"

# 獲取 AWS 帳戶 ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 建立日誌群組
aws logs create-log-group \
  --log-group-name /ecs/${PREFIX} \
  --region $AWS_REGION

echo "已建立日誌群組: /ecs/${PREFIX}"


# 建立 task definition
cat > task-definition.json << EOF
{
  "family": "${PREFIX}-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${PREFIX}-task-execution-role",
  "containerDefinitions": [
    {
      "name": "mario-container",
      "image": "${MARIO_IMAGE}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${PREFIX}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

# 註冊任務定義
aws ecs register-task-definition \
  --cli-input-json file://task-definition.json \
  --region $AWS_REGION

echo "已註冊任務定義: ${PREFIX}-task"

# 等待 IAM 角色傳播
echo "等待 IAM 角色傳播 (30 秒)..."
sleep 30

# 建立 ECS 服務
aws ecs create-service \
  --cluster ${PREFIX}-cluster \
  --service-name ${PREFIX}-service \
  --task-definition ${PREFIX}-task \
  --desired-count 2 \
  --launch-type FARGATE \
  --platform-version LATEST \
  --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET_1},${PRIVATE_SUBNET_2}],securityGroups=[${ECS_SG}],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=${TG_ARN},containerName=mario-container,containerPort=8080" \
  --region $AWS_REGION

echo "已建立 ECS 服務: ${PREFIX}-service"