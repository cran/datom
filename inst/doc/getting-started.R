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
# project_name <- "STUDY_001"          # logical project name (recorded in metadata)
# repo_name    <- "study-001-data"     # GitHub repo name for the metadata repo
# 
# # dev_dir  -- your local clone of the metadata git repo (stays on your machine)
# # data_dir -- where parquet bytes are written; point at a shared location
# #             (network mount, or an S3 store) for a real team space. Temp dirs
# #             are used here so the article leaves nothing behind.
# dev_dir  <- path(tempdir(), "study_001_dev")
# data_dir <- path(tempdir(), "study_001_data")
# 
# # Your GitHub personal access token (PAT), scoped to `repo`. Stored once in your
# # OS keychain with keyring::key_set("GITHUB_PAT"); read here by name so the
# # token never appears in your code or command history.
# github_pat <- keyring::key_get("GITHUB_PAT")
# # ---------------------------------------------------------------------------
# 
# dir_create(data_dir)

## -----------------------------------------------------------------------------
# store <- datom_store(
#   governance = NULL,
#   data       = datom_store_local(path = data_dir),
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
# # Metadata layout in the git clone (note input_files/ -- your sync inbox)
# fs::dir_tree(dev_dir)
# 
# # Storage layout (empty until first sync)
# fs::dir_tree(data_dir)

## -----------------------------------------------------------------------------
# conn <- datom_get_conn(path = dev_dir, store = store)
# print(conn)
# #> -- datom connection
# #> * Project: "STUDY_001"
# #> * Role: "developer"
# #> * Backend: "local"
# #> * Root: "/tmp/.../study_001_data"
# #> * Path: "/tmp/.../study_001_dev"
# #> * Governance: not attached

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
# manifest
# #>   name  file         format original_file_sha status
# #> 1   dm  .../dm.csv   csv    7a3b...           new

## -----------------------------------------------------------------------------
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
# 
# datom_read(conn, "dm")

## -----------------------------------------------------------------------------
# file_delete(path(input_dir, "dm.csv"))
# datom_read(conn, "dm")   # still works -- storage is the permanent record

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
# # Read the current version (month 2)
# nrow(datom_read(conn, "dm"))
# #> [1] 16
# 
# # Read the prior version (month 1) by its SHA
# hist   <- datom_history(conn, "dm")
# m1_ver <- hist$version[nrow(hist)]   # oldest row is the month-1 version
# nrow(datom_read(conn, "dm", version = m1_ver))
# #> [1] 4

## -----------------------------------------------------------------------------
# manifest <- datom_sync_manifest(conn)
# #> i Scanned 1 file: 0 new, 0 changed, 1 unchanged.
# 
# datom_sync(conn, manifest)
# #> i No new or changed files. Nothing to sync.

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

## -----------------------------------------------------------------------------
# manifest <- datom_sync_manifest(conn)
# #> i Scanned 4 files: 3 new, 1 changed, 0 unchanged.
# manifest
# #>   name  file         format original_file_sha status
# #> 1   dm  .../dm.csv   csv    c41a...           changed
# #> 2   ex  .../ex.csv   csv    9b08...           new
# #> 3   lb  .../lb.csv   csv    72d3...           new
# #> 4   ae  .../ae.csv   csv    1e4a...           new
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
# datom_status(conn)
# #> -- datom status: STUDY_001
# #> v Git: clean, in sync with origin
# #> i Tables on local: 4
# #> i Last commit: <sha> "Update ae"

## -----------------------------------------------------------------------------
# datom_validate(conn)
# #> v 4 tables validated.
# #> v Manifest <-> data store: consistent.
# #> v Manifest <-> git history: consistent.

## -----------------------------------------------------------------------------
# reader_store <- datom_store(
#   governance = NULL,
#   data       = datom_store_local(path = data_dir)   # same data location
# )                                                    # no PAT -> reader role
# 
# reader_conn <- datom_get_conn(store = reader_store, project_name = project_name)
# print(reader_conn)
# #> -- datom connection
# #> * Project: "STUDY_001"
# #> * Role: "reader"
# #> * Backend: "local"

## -----------------------------------------------------------------------------
# datom_read(reader_conn, "lb")   # labs, current version from storage

## -----------------------------------------------------------------------------
# # Derive a summary table in code
# lb <- datom_read(conn, "lb")
# lb_summary <- dplyr::summarise(
#   dplyr::group_by(lb, LBTESTCD),
#   n = dplyr::n(),
#   .groups = "drop"
# )
# 
# # Write it as a versioned table, declaring its parent for lineage.
# # datom_parent() resolves the parent's data_sha and source_lineage from
# # the stored metadata snapshot -- always use it instead of a raw list.
# datom_write(
#   conn,
#   data    = lb_summary,
#   name    = "lb_summary",
#   message = "Lab test counts from month-3 LB",
#   parents = list(
#     datom_parent(conn, table = "lb", version = datom_history(conn, "lb")$version[1])
#   )
# )
# #> v Wrote "lb_summary" (full): "b9c4e21a"

## ----eval = TRUE--------------------------------------------------------------
library(datom)

lb_summary <- data.frame(LBTESTCD = c("ALT", "AST"), n = c(12L, 12L))
datom_check_hashable(lb_summary)

## ----eval = TRUE--------------------------------------------------------------
messy <- data.frame(id = 1:2)
messy$measurements <- list(c(1, 2), c(3, 4))

report <- datom_check_hashable(messy)
report$recourse[report$status == "unsupported"]

## -----------------------------------------------------------------------------
# # Option A -- full scripted teardown (deletes local files AND the GitHub repo).
# # Do this BEFORE any manual unlink().
# datom_repo_delete(conn, confirm = "STUDY_001")

## -----------------------------------------------------------------------------
# # Option B -- local only (the GitHub repo stays; delete it from the UI later).
# unlink(c(dev_dir, data_dir), recursive = TRUE)

