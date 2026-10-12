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

# Object prefixes in $BUCKET (content-addressed <sha256>.<ext>, uploaded --no-clobber, immutable):
#   sky/      sky inputs + generated textures (tools/sky_assets.sh, pins data/sky/SHA256SUMS)
#   planets/  planet albedo textures, Solar System Scope 2k CC BY 4.0 (M5.2a; tools/planet_assets.sh,
#             pins data/planets/SHA256SUMS, attribution data/planets/CREDITS). No extra IAM: the
#             bucket-wide public read above covers every prefix.

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

# 8. Build-time AI generation (D-20, Mark 2026-10-02): a Gemini API key owned by
#    the project, restricted to the Generative Language API, stored only in
#    Secret Manager (never printed, never in git). Read it with:
#      gcloud secrets versions access latest --secret=gemini-api-key --project=stapledons-voyage
#    The unattended loop never spends; only attended runs read this secret.
gcloud services enable generativelanguage.googleapis.com apikeys.googleapis.com \
  secretmanager.googleapis.com billingbudgets.googleapis.com --project="$PROJECT_ID"
KEY_UID=$(gcloud services api-keys create --project="$PROJECT_ID" \
  --display-name="stapledons-voyage build-time generation (Gemini)" \
  --api-target=service=generativelanguage.googleapis.com --format="value(response.uid)")
gcloud secrets create gemini-api-key --project="$PROJECT_ID" --replication-policy=automatic \
  --labels=app=stapledons-voyage,purpose=build-time-ai || true
gcloud services api-keys get-key-string "$KEY_UID" --project="$PROJECT_ID" --format="value(keyString)" \
  | tr -d '\n' | gcloud secrets versions add gemini-api-key --project="$PROJECT_ID" --data-file=-

# 9. Monthly budget alert, about US$20. The billing account is in DKK, so the
#    amount is in DKK. --billing-project routes the API quota to this project
#    (the caller's default project may not have the Budget API enabled), and
#    --filter-projects needs the project NUMBER, not the ID.
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
gcloud billing budgets create --billing-project="$PROJECT_ID" --billing-account="$BILLING_ACCOUNT" \
  --display-name="stapledons-voyage monthly" --budget-amount=140DKK \
  --filter-projects="projects/$PROJECT_NUMBER" \
  --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0

# 10. OpenRouter key for text generation (Mark 2026-10-02: "have both options").
#     The secret is created empty; Mark adds the value himself so it never
#     passes through a chat or a log:
#       read -s OR_KEY && printf '%s' "$OR_KEY" | gcloud secrets versions add openrouter-api-key --project=stapledons-voyage --data-file=- && unset OR_KEY
gcloud secrets create openrouter-api-key --project="$PROJECT_ID" --replication-policy=automatic \
  --labels=app=stapledons-voyage,purpose=build-time-ai || true
