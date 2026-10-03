## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment  = "#>",
  eval     = FALSE
)

## ----settings-liver-safety----------------------------------------------------
# project_liver_safety <- "study001-liver-safety"
# prefix_liver_safety  <- "liver-safety/"
# repo_liver_safety    <- "study001-liver-safety"   # GitHub repo name
# set_liver_safety     <- "study001-liver-safety"   # the set this project owns
# workdir_liver_safety <- fs::path(tempdir(), "study001-liver-safety")

## ----stores-liver-safety------------------------------------------------------
# store_write_liver_safety <- datom_store(
#   data = datom_store_s3(
#     bucket     = bucket,
#     prefix     = prefix_liver_safety,
#     region     = region,
#     access_key = Sys.getenv("AWS_ACCESS_KEY_ID"),
#     secret_key = Sys.getenv("AWS_SECRET_ACCESS_KEY")
#   ),
#   github_pat = Sys.getenv("GITHUB_PAT")
# )
# 
# store_read_liver_safety <- datom_store(
#   data = datom_store_s3(
#     bucket     = bucket,
#     prefix     = prefix_liver_safety,
#     region     = region,
#     access_key = Sys.getenv("AWS_ACCESS_KEY_ID"),
#     secret_key = Sys.getenv("AWS_SECRET_ACCESS_KEY")
#   )
# )

## ----init-liver-safety--------------------------------------------------------
# datom_init_repo(
#   path         = workdir_liver_safety,
#   project_name = project_liver_safety,
#   store        = store_write_liver_safety,
#   create_repo  = TRUE,
#   repo_name    = repo_liver_safety,
#   mode         = "product",
#   set          = set_liver_safety
# )
# #> v Created GitHub repo ".../study001-liver-safety".
# #> v Initialized datom repository "study001-liver-safety" at '.../study001-liver-safety'

## ----conns-liver-safety-------------------------------------------------------
# conn_write_liver_safety <- datom_get_conn(
#   path  = workdir_liver_safety,
#   store = store_write_liver_safety
# )
# 
# conn_read_liver_safety <- datom_get_conn(
#   store        = store_read_liver_safety,
#   project_name = project_liver_safety
# )

## ----v1-preview---------------------------------------------------------------
# m <- datom_sync_manifest(
#   conn    = conn_write_liver_safety,
#   sources = list(conn_read_imported)
# )
# #> i Mapped 4 artifacts from 1 source: 4 new, 0 changed, 0 unchanged.
# 
# m[, c("project", "name", "kind", "status")]
# #>             project name  kind status
# #> 1 study001-imported   ae table    new
# #> 2 study001-imported   dm table    new
# #> 3 study001-imported   ex table    new
# #> 4 study001-imported   lb table    new

## ----v1-----------------------------------------------------------------------
# x <- datom_sync(
#   conn     = conn_write_liver_safety,
#   manifest = m,
#   sources  = list(conn_read_imported)
# )
# #> v Applied 4 rows: 4 added, 0 repointed.
# #> project study001-imported:
# #>   ae  added at 075773e9
# #>   dm  added at 773e6862
# #>   ex  added at 8dbcc9a7
# #>   lb  added at 435bccb0
# #> i Nothing has been written. Write the set with `datom_write_set(conn, x)`.
# 
# v1 <- datom_write_set(
#   conn    = conn_write_liver_safety,
#   members = x,
#   tags    = list(description = "Liver safety, study001")
# )
# #> v Wrote set "study001-liver-safety" (4 members): "d2d0456b"

## ----v1-version---------------------------------------------------------------
# v1$metadata_sha
# #> [1] "d2d0456b719244fe18d01f74a59b4e77637108405b716037c8e8b960dc15d786"

## ----derive-script------------------------------------------------------------
# # R/derive_liver_flags.R
# #
# # One row per subject: age, sex, dose, and peak ALT and AST as a multiple of
# # the upper limit of normal. Reads its inputs through the set `x`, so it uses
# # exactly the versions the set pins.
# derive_liver_flags <- function(x, conn_input) {
#   dm <- datom_fetch_member(conn = conn_input, x = x, member = "dm")
#   ex <- datom_fetch_member(conn = conn_input, x = x, member = "ex")
#   lb <- datom_fetch_member(conn = conn_input, x = x, member = "lb")
# 
#   peak_xuln <- function(test) {
#     rows <- lb[lb$LBTESTCD == test, ]
#     tapply(X = rows$LBORRES / rows$LBORNRHI, INDEX = rows$USUBJID, FUN = max)
#   }
# 
#   liver_flags <- merge(
#     x  = dm[, c("USUBJID", "AGE", "SEX")],
#     y  = ex[, c("USUBJID", "EXDOSE")],
#     by = "USUBJID"
#   )
#   liver_flags$ALT_PEAK_XULN <- as.numeric(peak_xuln("ALT")[liver_flags$USUBJID])
#   liver_flags$AST_PEAK_XULN <- as.numeric(peak_xuln("AST")[liver_flags$USUBJID])
#   liver_flags$ELEVATED <- liver_flags$ALT_PEAK_XULN > 1 |
#     liver_flags$AST_PEAK_XULN > 1
# 
#   liver_flags
# }

## ----v2-----------------------------------------------------------------------
# source(fs::path(workdir_liver_safety, "R", "derive_liver_flags.R"))
# 
# x <- datom_get_set(conn = conn_read_liver_safety, name = set_liver_safety)
# 
# liver_flags <- derive_liver_flags(x = x, conn_input = conn_read_imported)
# 
# liver_flags_written <- datom_write(
#   conn    = conn_write_liver_safety,
#   data    = liver_flags,
#   name    = "liver_flags",
#   parents = datom_parent(
#     conn  = conn_read_imported,
#     table = c("dm", "ex", "lb"),
#     x     = x
#   )
# )
# #> v Wrote "liver_flags" (full): "dafdb954"
# 
# x <- datom_add_member(
#   x       = x,
#   member  = "liver_flags",
#   version = liver_flags_written$metadata_sha,
#   tags    = list(type = "output"),
#   conn    = conn_read_liver_safety
# )
# #> i Nothing has been written. Write the set with `datom_write_set(conn, x)`.
# 
# v2 <- datom_write_set(
#   conn          = conn_write_liver_safety,
#   members       = x,
#   include_paths = "R"
# )
# #> v Wrote set "study001-liver-safety" (5 members): "66d721f3"

## ----use-structure------------------------------------------------------------
# x <- datom_get_set(conn = conn_read_liver_safety, name = set_liver_safety)
# print(x)
# #>
# #> -- datom set: "study001-liver-safety"
# #> * Project: "study001-liver-safety"
# #> * Version: "66d721f34ab2d8419b952fc267560218b06df6ea065669206277c1a1aa0a21ad"
# #> * Members: 5
# #> * Tags: description=Liver safety, study001
# #>   * ae (table) type=input
# #>   * dm (table) type=input
# #>   * ex (table) type=input
# #>   * lb (table) type=input
# #>   * liver_flags (table) type=output
# #> i Fetch a member with `datom_fetch_member(conn, x, "ae")`.
# 
# dp <- datom_structure_members(x = x, by = "type")
# 
# head(dp$output$liver_flags(conn = conn_read_liver_safety))
# #> # A tibble: 6 x 7
# #>   USUBJID         AGE SEX   EXDOSE ALT_PEAK_XULN AST_PEAK_XULN ELEVATED
# #>   <chr>         <int> <chr>  <int>         <dbl>         <dbl> <lgl>
# #> 1 STUDY-001-001    71 F        200         0.416         0.648 FALSE
# #> 2 STUDY-001-002    27 M        200         0.711         0.585 FALSE
# #> 3 STUDY-001-003    35 M          0         0.911         0.455 FALSE
# #> 4 STUDY-001-004    68 M        200         0.752         0.728 FALSE
# #> 5 STUDY-001-005    43 M        200         0.846         0.535 FALSE
# #> 6 STUDY-001-006    60 F          0         0.404         0.722 FALSE
# 
# nrow(dp$input$lb(conn = conn_read_imported))
# #> [1] 205

## ----use-list-----------------------------------------------------------------
# datom_list_members(x = x)[, c("name", "project", "key", "value")]
# #>          name               project  key  value
# #> 1          ae     study001-imported type  input
# #> 2          dm     study001-imported type  input
# #> 3          ex     study001-imported type  input
# #> 4          lb     study001-imported type  input
# #> 5 liver_flags study001-liver-safety type output

## ----use-history--------------------------------------------------------------
# set_history <- datom_history(conn = conn_read_liver_safety,
#                              name = set_liver_safety, short_hash = TRUE)
# set_history[, c("version", "commit_message")]
# #>    version                              commit_message
# #> 1 66d721f3  Update study001-liver-safety: add 1 member
# #> 2 d2d0456b Update study001-liver-safety: add 4 members
# 
# datom_get_set(
#   conn    = conn_read_liver_safety,
#   name    = set_liver_safety,
#   version = v1$metadata_sha
# )
# #>
# #> -- datom set: "study001-liver-safety"
# #> * Project: "study001-liver-safety"
# #> * Version: "d2d0456b719244fe18d01f74a59b4e77637108405b716037c8e8b960dc15d786"
# #> * Members: 4
# #> * Tags: description=Liver safety, study001
# #>   * ae (table) type=input
# #>   * dm (table) type=input
# #>   * ex (table) type=input
# #>   * lb (table) type=input
# #> i Fetch a member with `datom_fetch_member(conn, x, "ae")`.

## ----refresh-sync-------------------------------------------------------------
# for (domain in c("dm", "ex", "lb", "ae", "vs")) {
#   write.csv(
#     x         = datom_example_data(domain = domain, cutoff_date = "2026-04-28"),
#     file      = fs::path(inputs_imported, paste0(domain, ".csv")),
#     row.names = FALSE
#   )
# }
# 
# manifest <- datom_sync_manifest(conn = conn_write_imported)
# #> i Scanned 5 files: 1 new, 4 changed, 0 unchanged.
# 
# synced <- datom_sync(conn = conn_write_imported, manifest = manifest)
# #> i Syncing 5 tables...
# #> v Wrote "ae" (full): "97e2a95a"
# #> v "ae" synced (changed).
# #> v Wrote "dm" (full): "a87789e0"
# #> v "dm" synced (changed).
# #> v Wrote "ex" (full): "b59939d6"
# #> v "ex" synced (changed).
# #> v Wrote "lb" (full): "dc682195"
# #> v "lb" synced (changed).
# #> v Wrote "vs" (full): "28c748b0"
# #> v "vs" synced (new).
# #> i Sync complete: 5 succeeded, 0 failed, 0 skipped.

## ----refresh-inputs-----------------------------------------------------------
# m <- datom_sync_manifest(
#   conn    = conn_write_liver_safety,
#   sources = list(conn_read_imported)
# )
# #> i Mapped 5 artifacts from 1 source: 1 new, 4 changed, 0 unchanged.
# 
# m[, c("project", "name", "kind", "status")]
# #>             project name  kind  status
# #> 1 study001-imported   ae table changed
# #> 2 study001-imported   dm table changed
# #> 3 study001-imported   ex table changed
# #> 4 study001-imported   lb table changed
# #> 5 study001-imported   vs table     new
# 
# x <- datom_sync(
#   conn     = conn_write_liver_safety,
#   manifest = m,
#   sources  = list(conn_read_imported)
# )
# #> v Applied 5 rows: 1 added, 4 repointed.
# #> project study001-imported:
# #>   ae  075773e9 -> 97e2a95a
# #>   dm  773e6862 -> a87789e0
# #>   ex  8dbcc9a7 -> b59939d6
# #>   lb  435bccb0 -> dc682195
# #>   vs  added at 28c748b0
# #> i Nothing has been written. Write the set with `datom_write_set(conn, x)`.

## ----refresh-output-----------------------------------------------------------
# liver_flags <- derive_liver_flags(x = x, conn_input = conn_read_imported)
# 
# liver_flags_written <- datom_write(
#   conn    = conn_write_liver_safety,
#   data    = liver_flags,
#   name    = "liver_flags",
#   parents = datom_parent(
#     conn  = conn_read_imported,
#     table = c("dm", "ex", "lb"),
#     x     = x
#   )
# )
# #> v Wrote "liver_flags" (full): "0f89dd1b"
# 
# x <- datom_update_members(
#   x    = x,
#   conn = conn_read_liver_safety,
#   tags = list(type = "output")
# )
# #> v Repointed 1 member, of 1 selected.
# #> project study001-liver-safety:
# #>   liver_flags  dafdb954 -> 0f89dd1b
# #> i Nothing has been written. Write the set with `datom_write_set(conn, x)`.
# 
# v3 <- datom_write_set(
#   conn          = conn_write_liver_safety,
#   members       = x,
#   include_paths = "R"
# )
# #> v Wrote set "study001-liver-safety" (6 members): "35e39f62"

## ----teardown-----------------------------------------------------------------
# datom_storage_delete_prefix(conn = conn_write_liver_safety)
# datom_repo_delete(conn = conn_write_liver_safety, confirm = project_liver_safety)
# 
# datom_storage_delete_prefix(conn = conn_write_imported)
# datom_repo_delete(conn = conn_write_imported, confirm = project_imported)

