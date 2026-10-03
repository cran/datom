## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment  = "#>",
  eval     = FALSE
)

## ----keyring-setup------------------------------------------------------------
# keyring::key_set(service = "GITHUB_PAT")
# keyring::key_set(service = "AWS_ACCESS_KEY_ID")
# keyring::key_set(service = "AWS_SECRET_ACCESS_KEY")

## ----secrets------------------------------------------------------------------
# Sys.setenv(
#   GITHUB_PAT            = keyring::key_get(service = "GITHUB_PAT"),
#   AWS_ACCESS_KEY_ID     = keyring::key_get(service = "AWS_ACCESS_KEY_ID"),
#   AWS_SECRET_ACCESS_KEY = keyring::key_get(service = "AWS_SECRET_ACCESS_KEY")
# )

## ----settings-----------------------------------------------------------------
# library(datom)
# 
# # --- Settings you control ----------------------------------------------------
# bucket           <- "study001"            # one bucket per study
# region           <- "us-east-1"
# 
# project_imported <- "study001-imported"   # recorded in the project's metadata
# prefix_imported  <- "imported/"           # this project's folder in the bucket
# repo_imported    <- "study001-imported"   # GitHub repo name
# 
# # Local working folder for the metadata repository. The data never lands here;
# # it goes straight to S3.
# workdir_imported <- fs::path(tempdir(), "study001-imported")

## ----store-write--------------------------------------------------------------
# store_write_imported <- datom_store(
#   data = datom_store_s3(
#     bucket     = bucket,
#     prefix     = prefix_imported,
#     region     = region,
#     access_key = Sys.getenv("AWS_ACCESS_KEY_ID"),
#     secret_key = Sys.getenv("AWS_SECRET_ACCESS_KEY")
#   ),
#   github_pat = Sys.getenv("GITHUB_PAT")
# )

## ----init---------------------------------------------------------------------
# datom_init_repo(
#   path         = workdir_imported,
#   project_name = project_imported,
#   store        = store_write_imported,
#   create_repo  = TRUE,
#   repo_name    = repo_imported
# )
# #> v Created GitHub repo ".../study001-imported".
# #> v Initialized datom repository "study001-imported" at '.../study001-imported'

## ----conn-write---------------------------------------------------------------
# conn_write_imported <- datom_get_conn(
#   path  = workdir_imported,
#   store = store_write_imported
# )
# print(conn_write_imported)
# #>
# #> -- datom connection
# #> * Project: "study001-imported"
# #> * Backend: "s3"
# #> * Role: "developer"
# #> * Data root: "study001"
# #> * Data prefix: "imported/"
# #> * Data region: "us-east-1"
# #> * Governance: not attached
# #> * Path: '.../study001-imported'
# #> * Data repo: <https://github.com/.../study001-imported.git>

## ----step1-write--------------------------------------------------------------
# inputs_imported <- fs::path(workdir_imported, "input_files")
# 
# write.csv(
#   x         = datom_example_data(domain = "dm", cutoff_date = "2026-01-28"),
#   file      = fs::path(inputs_imported, "dm.csv"),
#   row.names = FALSE
# )

## ----step1-sync---------------------------------------------------------------
# manifest <- datom_sync_manifest(conn = conn_write_imported)
# #> i Scanned 1 file: 1 new, 0 changed, 0 unchanged.
# 
# synced <- datom_sync(conn = conn_write_imported, manifest = manifest)
# #> i Syncing 1 table...
# #> v Wrote "dm" (full): "153bff41"
# #> v "dm" synced (new).
# #> i Sync complete: 1 succeeded, 0 failed, 0 skipped.

## ----step1-list---------------------------------------------------------------
# datom_list(conn = conn_write_imported)
# #>   name  kind current_version current_data_sha         last_updated
# #> 1   dm table        153bff41         decbafd2 2026-09-27T05:58:03Z
# 
# dm_history <- datom_history(conn = conn_write_imported, name = "dm",
#                             short_hash = TRUE)
# dm_history[, c("version", "timestamp", "commit_message")]
# #>    version            timestamp commit_message
# #> 1 153bff41 2026-09-27T05:58:03Z  Sync dm (new)

## ----step1-delete-------------------------------------------------------------
# fs::file_delete(fs::path(inputs_imported, "dm.csv"))
# nrow(datom_read(conn = conn_write_imported, name = "dm"))
# #> [1] 4

## ----step2--------------------------------------------------------------------
# write.csv(
#   x         = datom_example_data(domain = "dm", cutoff_date = "2026-02-28"),
#   file      = fs::path(inputs_imported, "dm.csv"),
#   row.names = FALSE
# )
# 
# manifest <- datom_sync_manifest(conn = conn_write_imported)
# #> i Scanned 1 file: 0 new, 1 changed, 0 unchanged.
# 
# synced <- datom_sync(conn = conn_write_imported, manifest = manifest)
# #> i Syncing 1 table...
# #> v Wrote "dm" (full): "0fac26cd"
# #> v "dm" synced (changed).
# #> i Sync complete: 1 succeeded, 0 failed, 0 skipped.

## ----step2-read---------------------------------------------------------------
# dm_history <- datom_history(conn = conn_write_imported, name = "dm",
#                             short_hash = TRUE)
# dm_history[, c("version", "timestamp", "commit_message")]
# #>    version            timestamp    commit_message
# #> 1 0fac26cd 2026-09-27T05:58:10Z Sync dm (changed)
# #> 2 153bff41 2026-09-27T05:58:03Z     Sync dm (new)
# 
# nrow(datom_read(conn = conn_write_imported, name = "dm"))
# #> [1] 16
# 
# dm_version <- dm_history$version[nrow(dm_history)]   # oldest row: month 1
# nrow(datom_read(conn = conn_write_imported, name = "dm", version = dm_version))
# #> [1] 4

## ----step3--------------------------------------------------------------------
# manifest <- datom_sync_manifest(conn = conn_write_imported)
# #> i Scanned 1 file: 0 new, 0 changed, 1 unchanged.
# 
# synced <- datom_sync(conn = conn_write_imported, manifest = manifest)
# #> i No new or changed files. Nothing to sync.

## ----step4--------------------------------------------------------------------
# for (domain in c("dm", "ex", "lb", "ae")) {
#   write.csv(
#     x         = datom_example_data(domain = domain, cutoff_date = "2026-03-28"),
#     file      = fs::path(inputs_imported, paste0(domain, ".csv")),
#     row.names = FALSE
#   )
# }
# 
# manifest <- datom_sync_manifest(conn = conn_write_imported)
# #> i Scanned 4 files: 3 new, 1 changed, 0 unchanged.
# 
# synced <- datom_sync(conn = conn_write_imported, manifest = manifest)
# #> i Syncing 4 tables...
# #> v Wrote "ae" (full): "075773e9"
# #> v "ae" synced (new).
# #> v Wrote "dm" (full): "773e6862"
# #> v "dm" synced (changed).
# #> v Wrote "ex" (full): "8dbcc9a7"
# #> v "ex" synced (new).
# #> v Wrote "lb" (full): "435bccb0"
# #> v "lb" synced (new).
# #> i Sync complete: 4 succeeded, 0 failed, 0 skipped.

## ----step4-list---------------------------------------------------------------
# datom_list(conn = conn_write_imported)
# #>   name  kind current_version current_data_sha         last_updated
# #> 1   dm table        773e6862         e547f03d 2026-09-27T05:58:22Z
# #> 2   ae table        075773e9         d5f8dd5a 2026-09-27T05:58:17Z
# #> 3   ex table        8dbcc9a7         ab96afc3 2026-09-27T05:58:26Z
# #> 4   lb table        435bccb0         5d419c60 2026-09-27T05:58:31Z

## ----reader-------------------------------------------------------------------
# store_read_imported <- datom_store(
#   data = datom_store_s3(
#     bucket     = bucket,
#     prefix     = prefix_imported,
#     region     = region,
#     access_key = Sys.getenv("AWS_ACCESS_KEY_ID"),
#     secret_key = Sys.getenv("AWS_SECRET_ACCESS_KEY")
#   )
# )
# 
# conn_read_imported <- datom_get_conn(
#   store        = store_read_imported,
#   project_name = project_imported
# )
# 
# nrow(datom_read(conn = conn_read_imported, name = "lb"))
# #> [1] 205

## ----teardown-imported--------------------------------------------------------
# datom_storage_delete_prefix(conn = conn_write_imported)
# datom_repo_delete(conn = conn_write_imported, confirm = project_imported)

