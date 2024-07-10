# AWS 서버리스 웹 서비스 및 컨테이너를 사용한 배포 파이프라인 구축


## 프로젝트 개요

이 프로젝트는 AWS를 활용한 3 Tier Architecture에 기반한 서버리스 웹 서비스 및 컨테이너를 사용한 배포 파이프라인을 구축하는 것을 목표로 합니다. 이를 통해 고가용성, 보안, 모니터링 및 백업 기능을 포함한 완전한 인프라 환경을 구현합니다.

## 아키텍처 구성

### 개발환경
- AWS
- Terraform
- Docker
- Python
- Flask
- ECS Fargate
- DynamoDB

# 사전 작업 필요 사항
- AWS CLI 설치
- Docker 설치
- Terraform 설치
- Route53 호스팅 영역 생성 및 네임 서버 등록
- IAM AWS 사용자 Access Key 발급 및 등록 :  IAM - 사용자 - 보안 자격 증명 - 액세스 키 만들기
- IAM AWS 사용자 codeCommit에 대한 SSH 사용 컴퓨터의 Public Key 등록 : 사용자 - 보안 자격 증명 - SSH 퍼블릭키 업로드

### 인프라 관리
- **Infra:** Terraform을 통해 DEV 및 PRD 환경의 전체 AWS 서비스 리소스를 배포 및 관리합니다.

### 서버리스 서비스
- **Serverless Service:** ECS Fargate와 DynamoDB를 사용한 서버리스 서비스입니다.

### 보안
- **Security:** 
  - 접근 권한 관리: IAM, Security Group
  - 모니터링: CloudWatch, CloudTrail, SNS Topic
  - 백업: BackUp Vault

### CI/CD 파이프라인
- **CI/CD:** 블루그린 배포를 사용하여 CodeCommit, CodePipeline, CodeBuild, ECR, CodeDeploy로 구성된 CI/CD 파이프라인을 구축합니다.

### 비용 관리
- **Billing:** S3 버저닝 및 LifeCycle을 통해 비용을 관리합니다.

### 고가용성
- **High Availability:** 
  - Auto Scaling: 임계값 기반 Scale In/Out
  - 다중 AZ 로드밸런서 (LoadBalancer)

### API 및 서비스
- **API Gateway:** Lambda와 DynamoDB를 이용한 채팅 서버를 구현합니다.
- **EventBridge:** Lambda, S3, Slack, DynamoDB를 사용한 백업 및 삭제 자동화 솔루션을 구축합니다.


## 상세 설명

### 1. 인프라 배포 및 관리
Terraform을 통해 DEV와 PRD 환경의 AWS 리소스를 효율적으로 배포 및 관리합니다. 이는 코드 기반의 인프라 관리로 재사용성과 확장성을 높입니다.

### 2. 서버리스 서비스
ECS Fargate와 DynamoDB를 사용하여 서버리스 아키텍처를 구현함으로써 확장성과 비용 효율성을 극대화합니다.

### 3. 보안 및 모니터링
IAM과 Security Group을 통해 접근 권한을 엄격히 관리하며, CloudWatch와 CloudTrail을 사용해 실시간 모니터링 및 로그 관리를 수행합니다. 또한, SNS Topic을 통해 중요한 알림을 받을 수 있습니다.

### 4. CI/CD 파이프라인
블루그린 배포 전략을 적용한 CI/CD 파이프라인은 CodeCommit, CodePipeline, CodeBuild, ECR, CodeDeploy로 구성되어 있어 지속적 통합 및 배포를 자동화합니다.

### 5. 비용 관리
S3 버저닝 및 LifeCycle 정책을 통해 데이터의 저장 및 삭제 주기를 관리하여 비용을 최적화합니다.

### 6. 고가용성
Auto Scaling 및 다중 AZ 로드밸런서를 통해 시스템의 고가용성을 보장합니다.

### 7. API 및 서비스
API Gateway와 Lambda, DynamoDB를 활용하여 채팅 서버를 구현하고, EventBridge와 Lambda, S3, Slack, DynamoDB를 사용해 백업 및 삭제를 자동화합니다.
