# !/bin/bash

# 建 VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --region $AWS_REGION \
  --query 'Vpc.VpcId' \
  --output text)

echo "已建立 VPC: ${VPC_ID}"

# 標記
aws ec2 create-tags \
  --resources $VPC_ID \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-vpc

# DNS
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --region $AWS_REGION \
  --enable-dns-support "{\"Value\":true}"

aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --region $AWS_REGION \
  --enable-dns-hostnames "{\"Value\":true}"


# 建子網路
# 取得可用區域
AZ1=$(aws ec2 describe-availability-zones \
  --region $AWS_REGION \
  --query 'AvailabilityZones[0].ZoneName' \
  --output text)
AZ2=$(aws ec2 describe-availability-zones \
  --region $AWS_REGION \
  --query 'AvailabilityZones[1].ZoneName' \
  --output text)

echo "使用可用區域: ${AZ1} 和 ${AZ2}"

# 建 pubic subnet
PUBLIC_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone $AZ1 \
  --region $AWS_REGION \
  --query 'Subnet.SubnetId' \
  --output text)

aws ec2 create-tags \
  --resources $PUBLIC_SUBNET_1 \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-public-1

PUBLIC_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone $AZ2 \
  --region $AWS_REGION \
  --query 'Subnet.SubnetId' \
  --output text)

aws ec2 create-tags \
  --resources $PUBLIC_SUBNET_2 \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-public-2

echo "已建立公共子網路: ${PUBLIC_SUBNET_1} 和 ${PUBLIC_SUBNET_2}"

# 建 private subnet
PRIVATE_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.3.0/24 \
  --availability-zone $AZ1 \
  --region $AWS_REGION \
  --query 'Subnet.SubnetId' \
  --output text)

aws ec2 create-tags \
  --resources $PRIVATE_SUBNET_1 \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-private-1

PRIVATE_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.4.0/24 \
  --availability-zone $AZ2 \
  --region $AWS_REGION \
  --query 'Subnet.SubnetId' \
  --output text)

aws ec2 create-tags \
  --resources $PRIVATE_SUBNET_2 \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-private-2

echo "已建立私有子網路: ${PRIVATE_SUBNET_1} 和 ${PRIVATE_SUBNET_2}"


# 建 Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --region $AWS_REGION \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

aws ec2 create-tags \
  --resources $IGW_ID \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-igw

# 連接 Internet Gateway 到 VPC
aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID \
  --region $AWS_REGION

echo "已建立並連接 Internet Gateway: ${IGW_ID}"


# 建立 Route tables
PUBLIC_RTB=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $AWS_REGION \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-tags \
  --resources $PUBLIC_RTB \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-public-rtb

# 建立到網際網路的路由
aws ec2 create-route \
  --route-table-id $PUBLIC_RTB \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $AWS_REGION

# 將公共路由表與公共子網路關聯
aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RTB \
  --subnet-id $PUBLIC_SUBNET_1 \
  --region $AWS_REGION

aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RTB \
  --subnet-id $PUBLIC_SUBNET_2 \
  --region $AWS_REGION

echo "已建立並設置公共路由表: ${PUBLIC_RTB}"

# 啟用公共子網路自動分配公共 IP
aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_1 \
  --map-public-ip-on-launch \
  --region $AWS_REGION

aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_2 \
  --map-public-ip-on-launch \
  --region $AWS_REGION


# 分配彈性 IP
EIP_ALLOC=$(aws ec2 allocate-address \
  --domain vpc \
  --region $AWS_REGION \
  --query 'AllocationId' \
  --output text)

echo "已分配彈性 IP: ${EIP_ALLOC}"

# 建立 NAT Gateway
NAT_GW=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_1 \
  --allocation-id $EIP_ALLOC \
  --region $AWS_REGION \
  --query 'NatGateway.NatGatewayId' \
  --output text)

aws ec2 create-tags \
  --resources $NAT_GW \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-nat-gw

echo "NAT 閘道正在建立中: ${NAT_GW}"
echo "等待  NAT Gateway 變為可用..."

# 等待 NAT Gateway可用 
aws ec2 wait nat-gateway-available \
  --nat-gateway-ids $NAT_GW \
  --region $AWS_REGION

echo "NAT 閘道現在可用"

# 建立 private route table
PRIVATE_RTB=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $AWS_REGION \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-tags \
  --resources $PRIVATE_RTB \
  --region $AWS_REGION \
  --tags Key=Name,Value=${PREFIX}-private-rtb

# 建立到 NAT 閘道的路由
aws ec2 create-route \
  --route-table-id $PRIVATE_RTB \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW \
  --region $AWS_REGION

# 將私有路由表與私有子網路關聯
aws ec2 associate-route-table \
  --route-table-id $PRIVATE_RTB \
  --subnet-id $PRIVATE_SUBNET_1 \
  --region $AWS_REGION

aws ec2 associate-route-table \
  --route-table-id $PRIVATE_RTB \
  --subnet-id $PRIVATE_SUBNET_2 \
  --region $AWS_REGION

echo "已建立並設置私有路由表: ${PRIVATE_RTB}"
