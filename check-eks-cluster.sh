#!/bin/bash

echo "Checking for existing EKS clusters across all regions..."

regions=$(aws ec2 describe-regions \
  --query "Regions[].RegionName" \
  --output text)

for region in $regions; do
  clusters=$(aws eks list-clusters \
    --region "$region" \
    --query "clusters[]" \
    --output text)

  if [ -n "$clusters" ]; then
    echo "Region: $region"
    for c in $clusters; do
      echo "  - $c"
    done
  fi
done
echo "EKS cluster check completed."

