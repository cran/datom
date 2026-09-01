## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment  = "#>",
  eval     = FALSE
)

## -----------------------------------------------------------------------------
# library(datom)
# 
# project_name <- "my-study"
# bucket       <- "my-datom-bucket"
# prefix       <- "lineage-demo"
# region       <- "us-east-1"
# access_key   <- keyring::key_get("AWS_ACCESS_KEY_ID")
# secret_key   <- keyring::key_get("AWS_SECRET_ACCESS_KEY")
# github_pat   <- keyring::key_get("GITHUB_PAT")

## -----------------------------------------------------------------------------
# store <- datom_store(
#   governance = NULL,
#   data       = datom_store_s3(
#     bucket     = bucket,
#     prefix     = prefix,
#     region     = region,
#     access_key = access_key,
#     secret_key = secret_key
#   ),
#   github_pat = github_pat            # omit for a read-only reader connection
# )
# 
# conn <- datom_get_conn(path = "path/to/my-study-dev", store = store)

## -----------------------------------------------------------------------------
# raw_dm <- datom_example_data("dm")      # Demographics
# raw_lb <- datom_example_data("lb")      # Lab results

## -----------------------------------------------------------------------------
# # input_files/ lives inside the git clone and is the sync inbox.
# input_dir <- file.path("path/to/my-study-dev", "input_files")
# 
# write.csv(raw_dm, file.path(input_dir, "dm.csv"), row.names = FALSE)
# write.csv(raw_lb, file.path(input_dir, "lb.csv"), row.names = FALSE)
# 
# manifest <- datom_sync_manifest(conn)   # scans input_files/
# datom_sync(conn, manifest)              # onboards; self-lineage recorded

## -----------------------------------------------------------------------------
# datom_get_lineage(conn, "dm", depth = "source")
# #> [[1]]
# #> [[1]]$project
# #> [1] "my-study"
# #>
# #> [[1]]$table
# #> [1] "dm"
# #>
# #> [[1]]$version_sha
# #> [1] "abc123..."

## -----------------------------------------------------------------------------
# # Read the current versions
# raw_dm_data <- datom_read(conn, "dm")
# raw_lb_data <- datom_read(conn, "lb")
# 
# # ... cleaning logic ...
# dm_clean <- raw_dm_data  # simplified
# 
# # Retrieve the metadata shas to identify exactly which versions were read
# dm_version  <- datom_history(conn, "dm")[1, "version"]
# lb_version  <- datom_history(conn, "lb")[1, "version"]

## -----------------------------------------------------------------------------
# datom_write(
#   conn,
#   data    = dm_clean,
#   name    = "dm_clean",
#   parents = list(
#     datom_parent(conn, "dm", dm_version),
#     datom_parent(conn, "lb", lb_version)
#   )
# )

## -----------------------------------------------------------------------------
# datom_get_lineage(conn, "dm_clean", depth = "source")
# #> [[1]]
# #> $project
# #> [1] "my-study"
# #> $table
# #> [1] "dm"
# #> $version_sha
# #> [1] "abc123..."
# #>
# #> [[2]]
# #> $project
# #> [1] "my-study"
# #> $table
# #> [1] "lb"
# #> $version_sha
# #> [1] "def456..."

## -----------------------------------------------------------------------------
# datom_get_lineage(conn, "dm_clean", depth = "parents")
# #> [[1]]
# #> $source
# #> [1] "my-study"
# #> $table
# #> [1] "dm"
# #> $version
# #> [1] "..."   # metadata_sha of dm at derivation time

## -----------------------------------------------------------------------------
# # Identify the dm_clean version this analysis was derived from.
# clean_version <- datom_history(conn, "dm_clean")[1, "version"]
# 
# datom_write(
#   conn,
#   data    = analysis_pop,
#   name    = "analysis_pop",
#   parents = list(
#     datom_parent(conn, "dm_clean", clean_version)
#   )
# )

## -----------------------------------------------------------------------------
# # 1. Read the derived table's recorded parents. Each entry carries
# #    source, table, version, and data_sha -- enough to pick the parent's
# #    project connection and its pinned version.
# parents <- datom_get_parents(conn, "dm_clean")
# 
# # 2. Read each parent's source_lineage through a connection scoped to that
# #    parent's project. For same-project parents this is the same `conn`.
# parent_lineages <- lapply(parents, function(p) {
#   datom_get_lineage(conn, p$table, version = p$version, depth = "source")
# })
# 
# # 3. Union the parents' lineages (dedup by {project, table, version_sha}).
# recomputed <- datom_lineage_union(parent_lineages)
# 
# # 4. Compare against the derived table's recorded source_lineage.
# recorded <- datom_get_lineage(conn, "dm_clean", depth = "source")
# identical(recomputed, recorded)
# #> [1] TRUE

## -----------------------------------------------------------------------------
# # Cross-project variant: resolve a connection per parent project.
# parent_lineages <- lapply(parents, function(p) {
#   parent_conn <- conn_for_project(p$source)   # your connection resolver
#   datom_get_lineage(parent_conn, p$table, version = p$version,
#                     depth = "source")
# })
# recomputed <- datom_lineage_union(parent_lineages)

