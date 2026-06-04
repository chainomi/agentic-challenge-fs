#!/usr/bin/env bash
# One-time bootstrap of AWS prerequisites for the rdicidr Terraform CD pipeline.
# Run locally with admin-level credentials. Idempotent-ish: re-running create-*
# commands that already exist returns EntityAlreadyExists; safe to ignore.
#
# Account: 488144151286 | Region: us-east-1 | Repo: chainomi/agentic-challenge-fs
set -euo pipefail

ACCOUNT_ID=488144151286
REGION=us-east-1
BUCKET="rdicidr-tfstate-${ACCOUNT_ID}"
ROLE=rdicidr-gha-deploy
REPO=chainomi/agentic-challenge-fs
cd "$(dirname "$0")"

# 1) Terraform state bucket (versioned, encrypted, private). Terraform >=1.10
#    uses an S3-native lock object (*.tflock) via use_lockfile=true -> no DynamoDB.
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# 2) GitHub Actions OIDC identity provider (audience sts.amazonaws.com).
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
                    1c58a3a8518e8759bf075b76b750d4f2df264fcd

# 3) Deploy role assumed by GitHub Actions via OIDC. Trust is scoped to this
#    repo's devel/stage branches and pull_request subjects only.
aws iam create-role --role-name "$ROLE" \
  --assume-role-policy-document file://github-oidc-trust.json \
  --description "GitHub Actions OIDC deploy role for rdicidr (devel/stage)" \
  --max-session-duration 3600
aws iam put-role-policy --role-name "$ROLE" \
  --policy-name "${ROLE}-policy" \
  --policy-document file://deploy-role-policy.json

# 4) ECR repository for the application image.
aws ecr create-repository --repository-name rdicidr \
  --image-scanning-configuration scanOnPush=true \
  --image-tag-mutability MUTABLE --region "$REGION"

echo "Bootstrap complete:"
echo "  state bucket : $BUCKET"
echo "  deploy role  : arn:aws:iam::${ACCOUNT_ID}:role/${ROLE}"
echo "  ecr repo     : ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/rdicidr"
