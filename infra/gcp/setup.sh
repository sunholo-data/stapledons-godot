#!/bin/bash
# GCP setup for Stapledon's Voyage large assets (D-18, Mark attended 2026-10-02).
# Recorded as plain gcloud so it can be ported to Terraform later; see
# infra/gcp/README.md for the resource-by-resource mapping. Re-runnable: each
# step tolerates "already exists".
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-stapledons-voyage}"
ORG_ID="53196723689"                      # sunholo.com
BILLING_ACCOUNT="01BB66-647F04-B45EEF"    # Holosun Billing
BUCKET="${BUCKET:-stapledons-voyage-assets}"
LOCATION="EU"                             # multi-region; assets are read from anywhere

# 1. Project under the sunholo.com organisation.
gcloud projects create "$PROJECT_ID" --organization="$ORG_ID" --name="Stapledons Voyage" || true

# 2. Link billing.
gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT"

# 3. Enable Cloud Storage.
gcloud services enable storage.googleapis.com --project="$PROJECT_ID"

# 4. Bucket: uniform bucket-level access, content-addressed objects (never
#    overwritten), so versioning is unnecessary. Public access prevention is
#    left "inherited" so public read can be granted below.
gcloud storage buckets create "gs://$BUCKET" --project="$PROJECT_ID" \
  --location="$LOCATION" --uniform-bucket-level-access \
  --no-public-access-prevention || true   # flag is boolean; --public-access-prevention would ENFORCE it

# 5. Public read (objects only; nobody else can list-write).
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" \
  --member=allUsers --role=roles/storage.objectViewer

# 6. Labels for cost tracking.
gcloud storage buckets update "gs://$BUCKET" --update-labels=app=stapledons-voyage,purpose=assets

# 7. Private bucket for dev builds (D-18 follow-up, Mark 2026-10-02: "dev ones
#    in the bucket and we release via github"). The repo is private, so dev
#    builds must not be public: public access prevention is ENFORCED. Readers
#    authenticate with gcloud (project owners/editors can read). Old builds
#    expire after 30 days; macos/latest.json is the pointer.
DEV_BUCKET="${DEV_BUCKET:-stapledons-voyage-dev-builds}"
gcloud storage buckets create "gs://$DEV_BUCKET" --project="$PROJECT_ID" \
  --location="$LOCATION" --uniform-bucket-level-access \
  --public-access-prevention || true          # boolean flag: enforced
gcloud storage buckets update "gs://$DEV_BUCKET" --update-labels=app=stapledons-voyage,purpose=dev-builds
gcloud storage buckets update "gs://$DEV_BUCKET" --lifecycle-file="$(dirname "$0")/dev-builds-lifecycle.json"
