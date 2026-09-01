## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment  = "#>",
  eval     = FALSE
)

## -----------------------------------------------------------------------------
# library(datom)
# library(fs)
# 
# # --- Settings you control --------------------------------------------------
# project_name <- "STUDY_001"        # logical project name (recorded in metadata)
# repo_name    <- "study-001-data"   # GitHub repo name for the metadata repo
# 
# bucket <- "study-001-data"         # an S3 bucket you can read/write
#                                    #   (datom does NOT create buckets)
# prefix <- NULL                     # raw data at the bucket root; use e.g.
#                                    #   "adam/" for a derived-products prefix
# region <- "us-east-1"              # the bucket's AWS region
# 
# # Local working directory for the metadata git clone. The data itself never
# # lands here -- it goes straight to S3. A temp dir is fine for this walkthrough.
# dev_dir <- path(tempdir(), "study_001_dev")
# 
# # GitHub PAT (scoped to `repo`), read from your OS keychain by name.
# github_pat <- keyring::key_get("GITHUB_PAT")
# # ---------------------------------------------------------------------------

## -----------------------------------------------------------------------------
# # Option A -- keyring (recommended for an interactive developer machine)
# access_key <- keyring::key_get("AWS_ACCESS_KEY_ID")
# secret_key <- keyring::key_get("AWS_SECRET_ACCESS_KEY")

## -----------------------------------------------------------------------------
# # Option B -- environment variables (CI/CD, Docker)
# access_key <- Sys.getenv("AWS_ACCESS_KEY_ID")
# secret_key <- Sys.getenv("AWS_SECRET_ACCESS_KEY")

## -----------------------------------------------------------------------------
# # Option C -- inline (fine for a quick session; never commit these values)
# access_key <- "AKIAIOSFODNN7EXAMPLE"
# secret_key <- "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

## -----------------------------------------------------------------------------
# data_component <- datom_store_s3(
#   bucket     = bucket,
#   prefix     = prefix,
#   region     = region,
#   access_key = access_key,
#   secret_key = secret_key
# )
# 
# store <- datom_store(
#   governance = NULL,
#   data       = data_component,
#   github_pat = github_pat
# )

## -----------------------------------------------------------------------------
# datom_init_repo(
#   path         = dev_dir,
#   project_name = project_name,
#   store        = store,
#   create_repo  = TRUE,
#   repo_name    = repo_name
# )

## -----------------------------------------------------------------------------
# conn <- datom_get_conn(path = dev_dir, store = store)
# print(conn)
# #> -- datom connection
# #> * Project: "STUDY_001"
# #> * Backend: "s3"
# #> * Role: "developer"
# #> * Data root: "study-001-data"
# #> * Data region: "us-east-1"
# #> * Governance: not attached
# #> * Path: "/tmp/.../study_001_dev"
# #> * Data repo: <https://github.com/.../study-001-data>

## -----------------------------------------------------------------------------
# # The input folder lives inside the git clone but is gitignored.
# # Files placed here are the raw material for datom_sync().
# input_dir <- path(dev_dir, "input_files")
# 
# write.csv(
#   datom_example_data("dm", cutoff_date = "2026-01-28"),
#   path(input_dir, "dm.csv"),
#   row.names = FALSE
# )

## -----------------------------------------------------------------------------
# manifest <- datom_sync_manifest(conn)
# #> i Scanned 1 file: 1 new, 0 changed, 0 unchanged.
# 
# datom_sync(conn, manifest)
# #> i Syncing 1 table...
# #> v dm synced (new).
# #> i Sync complete: 1 succeeded, 0 failed, 0 skipped.

## -----------------------------------------------------------------------------
# datom_list(conn)
# #>   name current_version current_data_sha last_updated
# #> 1   dm        a8ee7a31         4b6d0a7e 2026-01-28T...
# 
# datom_history(conn, "dm")
# #>    version  data_sha timestamp            message
# #> 1 a8ee7a31 4b6d0a7e 2026-01-28T09:02:11Z dm synced from dm.csv

## -----------------------------------------------------------------------------
# file_delete(path(input_dir, "dm.csv"))
# datom_read(conn, "dm")   # still works -- reads from S3

## -----------------------------------------------------------------------------
# write.csv(
#   datom_example_data("dm", cutoff_date = "2026-02-28"),
#   path(input_dir, "dm.csv"),
#   row.names = FALSE
# )
# 
# manifest <- datom_sync_manifest(conn)
# #> i Scanned 1 file: 0 new, 1 changed, 0 unchanged.
# 
# datom_sync(conn, manifest)
# #> i Syncing 1 table...
# #> v dm synced (changed).
# #> i Sync complete: 1 succeeded, 0 failed, 0 skipped.

## -----------------------------------------------------------------------------
# datom_history(conn, "dm")
# #>    version  data_sha timestamp            message
# #> 1 5c1a3f7b 9e8f1c2d 2026-02-28T10:14:02Z dm synced from dm.csv
# #> 2 a8ee7a31 4b6d0a7e 2026-01-28T09:02:11Z dm synced from dm.csv
# 
# # Current version (month 2)
# nrow(datom_read(conn, "dm"))
# #> [1] 16
# 
# # Prior version (month 1) by SHA
# hist   <- datom_history(conn, "dm")
# m1_ver <- hist$version[nrow(hist)]   # oldest row is the month-1 version
# nrow(datom_read(conn, "dm", version = m1_ver))
# #> [1] 4

## -----------------------------------------------------------------------------
# manifest <- datom_sync_manifest(conn)
# #> i Scanned 1 file: 0 new, 0 changed, 1 unchanged.
# 
# datom_sync(conn, manifest)
# #> i All files unchanged. Nothing to sync.

## -----------------------------------------------------------------------------
# cutoff <- "2026-03-28"
# 
# write.csv(datom_example_data("dm", cutoff_date = cutoff),
#           path(input_dir, "dm.csv"), row.names = FALSE)
# write.csv(datom_example_data("ex", cutoff_date = cutoff),
#           path(input_dir, "ex.csv"), row.names = FALSE)
# write.csv(datom_example_data("lb", cutoff_date = cutoff),
#           path(input_dir, "lb.csv"), row.names = FALSE)
# write.csv(datom_example_data("ae", cutoff_date = cutoff),
#           path(input_dir, "ae.csv"), row.names = FALSE)
# 
# manifest <- datom_sync_manifest(conn)
# #> i Scanned 4 files: 3 new, 1 changed, 0 unchanged.
# 
# datom_sync(conn, manifest)
# #> i Syncing 4 tables...
# #> v dm synced (changed).
# #> v ex synced (new).
# #> v lb synced (new).
# #> v ae synced (new).
# #> i Sync complete: 4 succeeded, 0 failed, 0 skipped.

## -----------------------------------------------------------------------------
# datom_list(conn)
# #>   name current_version current_data_sha last_updated
# #> 1   ae        3a17b8e2         e91d04ff 2026-03-28T...
# #> 2   dm        d0922fc7         c2e80a14 2026-03-28T...
# #> 3   ex        f44910b5         88a73e02 2026-03-28T...
# #> 4   lb        718e02ca         4c3812dd 2026-03-28T...

## -----------------------------------------------------------------------------
# reader_store <- datom_store(
#   governance = NULL,
#   data       = datom_store_s3(
#     bucket     = bucket,
#     prefix     = prefix,
#     region     = region,
#     access_key = access_key,
#     secret_key = secret_key
#   )
# )                                         # no PAT -> reader role
# 
# reader_conn <- datom_get_conn(store = reader_store, project_name = project_name)
# 
# datom_read(reader_conn, "lb")   # labs, streamed directly from S3

## -----------------------------------------------------------------------------
# datom_repo_delete(conn, confirm = "STUDY_001")

