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
| AI key | Gemini API key (uid `d89b4007-b72c-4044-8d99-7b42da1babfd`), restricted to `generativelanguage.googleapis.com`; value only in Secret Manager secret `gemini-api-key` | `google_apikeys_key` + `google_secret_manager_secret` / `_version` (the value stays out of state, e.g. `ignore_changes`) |
| Budget | `stapledons-voyage monthly`, 140 DKK (about US$20) per month, alerts at 50/90/100 %, id `b42c642f-2bac-4ce0-a2cb-5f225ec786e9` | `google_billing_budget` |
| APIs (D-20) | `generativelanguage`, `apikeys`, `secretmanager`, `billingbudgets` | `google_project_service` |
| OpenRouter key | Secret Manager `openrouter-api-key`, created empty by `setup.sh` §10; Mark adds the value himself (`gcloud secrets versions add openrouter-api-key --data-file=-`), since an OpenRouter key can't be minted with gcloud. Text generation via AILANG's OpenRouter provider | `google_secret_manager_secret` (the version stays out of Terraform state, as for `gemini-api-key`) |
| Dev-builds bucket | `gs://stapledons-voyage-dev-builds`, `EU`, uniform access, public access prevention **enforced**, labels `purpose=dev-builds`, lifecycle: delete `macos/builds/*` after 30 days (`dev-builds-lifecycle.json`) | `google_storage_bucket` with `lifecycle_rule` |

## Layout

- `ATTRIBUTION.txt`: CC BY 4.0 credit for the NOIRLab source image.
- `sky/<sha256>.<ext>`: content-addressed textures and pinned inputs. Never
  overwritten; served with `Cache-Control: public, max-age=31536000, immutable`.
- `ai/<sha256>.<ext>`: the AI core layer's blobs (design ai-service-foundation
  (a4), sprint AI.8): accepted portraits and avatars, later voice lines. Same
  scheme as `sky/`; no new bucket resources. Pins: `data/ai/core/SHA256SUMS`.
  `make ai-core-assets` fetches them anonymously, `make ai-core-publish`
  (maintainers, gcloud) uploads them `--no-clobber`.

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

## Gotchas (budgets)

- Holosun Billing is in **DKK**. A `20USD` budget fails with a bare
  `INVALID_ARGUMENT`, and a plain `20` means 20 DKK.
- Pass `--billing-project=stapledons-voyage`, or the call uses your default
  gcloud project, which may not have the Budget API enabled.
- `--filter-projects` needs `projects/<number>` (216522869983), not the ID.
