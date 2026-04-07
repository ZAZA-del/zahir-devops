#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ONE-TIME BOOTSTRAP: create S3 bucket + DynamoDB table for Terraform state.
# Run this ONCE manually before the first `terraform init`.
# After running, commit infra/terraform/ and push — CI will handle the rest.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REGION="us-east-1"
ACCOUNT_ID="143575007958"
BUCKET="zahir-terraform-state-${ACCOUNT_ID}"
TABLE="zahir-terraform-locks"

echo "Creating S3 bucket: $BUCKET"
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION" 2>/dev/null \
  || echo "  Bucket already exists, continuing."

echo "Enabling versioning on $BUCKET"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo "Enabling server-side encryption on $BUCKET"
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}
    }]
  }'

echo "Blocking public access on $BUCKET"
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "Creating DynamoDB table: $TABLE"
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" 2>/dev/null \
  || echo "  Table already exists, continuing."

echo ""
echo "Bootstrap complete."
echo "Next steps:"
echo "  cd infra/terraform"
echo "  terraform init"
echo "  # Then run the import commands in README to bring existing"
echo "  # resources under Terraform management."
