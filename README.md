# Super Mario on AWS

- 通過部署經典遊戲 Super Mario 學習 AWS 雲端技術
- 結合多個 AWS 服務，使其通過網頁瀏覽器即可訪問
- 有趣好玩又實踐了雲端服務的整合應用


## 概述

此專案使用到以下 AWS 資源：
- VPC
- Subnet (跨兩個可用區域: 2個 public、2個 private)
- Internet Gateway
- NAT Gateway
- Security Groups
- ALB (Application Load Balancer)
- ECS(Elastic Container Service) Fargate 
- ECR (Elastic Container Registry)
- IAM
- CloudWatch

## 架構
```
Internet
    |
Internet Gateway
    |
Public Subnets (2 AZs)
    |
Application Load Balancer
    |
NAT Gateway
    |
Private Subnets (2 AZs)
    |
ECS Fargate Tasks (Super Mario Game)
```


## 檔案說明

```
super-mario-on-aws/
├── README.md                 # 專案說明
├── setup.sh                  # 01 設定環境、變數、區域
├── network.sh                # 02 建 network
├── security.sh               # 03 設置 SG
├── ECS.sh                    # 04 設置 ECS
├── ALB.sh                    # 05 設置 ALB
└── run.sh                    # 06 獲取連結，開始玩遊戲
```

## 更多內容請看文件
https://docs.google.com/document/d/1wmbh5QENNwfd5nnKAYs_erP2F_JSJmwEoUZDOrs5urI/edit?usp=sharing

Demo 影片: https://drive.google.com/file/d/1I7dvPnADRI9Ihc454vdBNOK9rrx7OK0i/view?usp=sharing