/*
  Reality-check 02 — issue #111 ("herding cattle": manage projects,
  repositories and read workspaces via a few lines of config).

  Mirrors the issue author's workflow (workspaces → projects → repositories,
  import then set defaults) using plain typed fields — no jsonencode required:

    1. bitbucket_workspaces  — data source read (workspaces coverage).
    2. bitbucket_projects    — created with TYPED fields (key/name/description/
                               is_private). Historically these were read-only and
                               a raw `request_body` was the only way; the schema
                               is now enriched so they are first-class.
    3. bitbucket_repos       — typed `description` + `project.key` fields, plus
                               a second repo driven entirely by `request_body`.

  The `description_suffix` variable exercises the #111 update-detection fix:
  apply once, then re-apply with `-var description_suffix=.` and confirm
  Terraform plans a real update (pre-fix it wrongly reported "no changes").
  `typed_use_request_body` exercises the #111 invalid-plan fix (adding a raw
  body to an existing typed repo).
*/

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    bitbucket = { source = "FabianSchurig/bitbucket" }
    random    = { source = "hashicorp/random" }
  }
}

provider "bitbucket" {}
provider "random" {}

# Uppercase alphanumeric project key (Bitbucket requires [A-Z0-9]).
resource "random_string" "project_key" {
  length  = 6
  upper   = true
  lower   = false
  numeric = true
  special = false
}

resource "random_pet" "repo" {
  length = 2
}

locals {
  project_key      = "TF${random_string.project_key.result}"
  base_description = "Reality-check 02 for issue #111${var.description_suffix}"
}

# 1) Read the workspace (data source). Proves workspace-level reads work.
data "bitbucket_workspaces" "current" {
  workspace = var.workspace
}

# 2) Project — created with TYPED fields (no jsonencode). This is the "few
#    lines of config" the issue author wanted for standardising many projects.
resource "bitbucket_projects" "proj" {
  count       = var.create_project ? 1 : 0
  workspace   = var.workspace
  key         = local.project_key
  name        = "TF Reality ${local.project_key}"
  description = "Project — ${local.base_description}"
  is_private  = true
}

# 3a) Repository using typed fields (description + project.key). Changing the
#     `description_suffix` here must produce a plan diff after import/create.
#
#     When `typed_use_request_body = true` this repo ALSO sets a raw
#     `request_body`, reproducing the second symptom from issue #111: adding a
#     jsonencode(...) body to an existing typed repo. Pre-fix that produced
#     "Provider produced invalid plan ... planned value cty.NullVal does not
#     match config value".
resource "bitbucket_repos" "typed" {
  workspace   = var.workspace
  repo_slug   = "tf-reality-typed-${random_pet.repo.id}"
  is_private  = true
  description = "Typed repo — ${local.base_description}"

  # Attach to the project created above when project creation is enabled.
  # `project` is an object attribute, so it uses `= { ... }` syntax.
  project = var.create_project ? { key = local.project_key } : null

  # Optional raw-body override (issue #111 symptom 2).
  request_body = var.typed_use_request_body ? jsonencode({
    description = "Typed repo — ${local.base_description}"
  }) : null

  depends_on = [bitbucket_projects.proj]
}

# 3b) Repository driven entirely by request_body (the jsonencode variant from
#     the issue). Validates the raw-body escape hatch on repos.
resource "bitbucket_repos" "raw_body" {
  count     = var.enable_request_body ? 1 : 0
  workspace = var.workspace
  repo_slug = "tf-reality-rawbody-${random_pet.repo.id}"
  request_body = jsonencode(merge(
    {
      is_private  = true
      description = "Raw-body repo — ${local.base_description}"
    },
    var.create_project ? { project = { key = local.project_key } } : {},
  ))

  depends_on = [bitbucket_projects.proj]
}

output "workspace_response" {
  value = data.bitbucket_workspaces.current.api_response
}

output "project_key" {
  value = var.create_project ? bitbucket_projects.proj[0].project_key : null
}

output "project_description" {
  value = var.create_project ? bitbucket_projects.proj[0].description : null
}

output "typed_repo_slug" {
  value = bitbucket_repos.typed.repo_slug
}

output "typed_repo_description" {
  value = bitbucket_repos.typed.description
}

output "raw_body_repo_slug" {
  value = var.enable_request_body ? bitbucket_repos.raw_body[0].repo_slug : null
}
