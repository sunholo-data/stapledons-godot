# GCP infrastructure

Large game assets (the M1.4 sky textures, about 164 MB) live in a public GCS
bucket rather than git (ledger D-18, Mark attended 2026-10-02). Dev builds go
to a private bucket (`make publish-dev`, installed with
`tools/install_review_build.sh --dev`). Releases stay in private GitHub
releases.

`setup.sh` records every command used to create the infrastructure, in order,
so it can be re-run or ported to Terraform. Created 2026-10-02 as
m@sunholo.com.

| Resource | Value | Terraform resource (for a later migration) |
|---|---|---|
| Project | `stapledons-voyage` (number 216522869983), org `sunholo.com` (53196723689) | `google_project` (`org_id`, `billing_account`) |
| Billing | Holosun Billing `01BB66-647F04-B45EEF` | `google_project.billing_account` |
| API | `storage.googleapis.com` | `google_project_service` |
| Bucket | `gs://stapledons-voyage-assets`, location `EU`, uniform bucket-level access, public access prevention `inherited`, labels `app=stapledons-voyage,purpose=assets` | `google_storage_bucket` (`uniform_bucket_level_access = true`, `public_access_prevention = "inherited"`) |
| Public read | `allUsers` → `roles/storage.objectViewer` on the bucket | `google_storage_bucket_iam_member` |
| Dev-builds bucket | `gs://stapledons-voyage-dev-builds`, `EU`, uniform access, public access prevention **enforced**, labels `purpose=dev-builds`, lifecycle: delete `macos/builds/*` after 30 days (`dev-builds-lifecycle.json`) | `google_storage_bucket` with `lifecycle_rule` |

## Layout

- `ATTRIBUTION.txt`: CC BY 4.0 credit for the NOIRLab source image.
- `sky/<sha256>.<ext>`: content-addressed textures and pinned inputs. Never
  overwritten; served with `Cache-Control: public, max-age=31536000, immutable`.

Public URL base: `https://storage.googleapis.com/stapledons-voyage-assets/`.

## Gotcha

`gcloud storage buckets create --public-access-prevention` is a boolean that
**enforces** prevention. Use `--no-public-access-prevention` (giving
`inherited`) before granting `allUsers` read. The first creation on 2026-10-02
hit this and was corrected with `buckets update --no-public-access-prevention`.

## Dev builds

- `make publish-dev` (needs gcloud auth) zips the current export, uploads it to
  `gs://stapledons-voyage-dev-builds/macos/builds/<git describe>.zip` with a
  `.sha256` file, and rewrites `macos/latest.json`.
- `tools/install_review_build.sh --dev` reads `latest.json`, downloads and
  verifies the zip, unzips it to `~/Applications`, clears the quarantine flag
  and opens the app. Without `--dev` it installs the latest GitHub release.
