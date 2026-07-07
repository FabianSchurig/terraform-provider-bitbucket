variable "workspace" {
  description = "Bitbucket workspace slug (set via TF_VAR_workspace or in .env at repository root)"
  type        = string
}

variable "description_suffix" {
  description = <<-EOT
    Text appended to every managed description. Used to reproduce issue #111:
    run apply once with the default empty value, then re-run with e.g. "."
    (`-var description_suffix=.`) and confirm Terraform actually plans an
    update instead of reporting "no changes".
  EOT
  type        = string
  default     = ""
}

variable "enable_request_body" {
  description = <<-EOT
    Toggle the raw `request_body = jsonencode(...)` repo scenario (the second
    half of issue #111). On a provider version that still has the bug this plans
    as an invalid value ("planned value cty.NullVal ... does not match config
    value"); set to false to validate the typed-field scenarios in isolation.
  EOT
  type        = bool
  default     = true
}

variable "create_project" {
  description = <<-EOT
    Toggle creating a bitbucket_projects resource (with typed fields) and
    attaching the typed repo to it. Set to false to validate the repo-only
    scenarios in isolation.
  EOT
  type        = bool
  default     = true
}

variable "typed_use_request_body" {
  description = <<-EOT
    When true, the typed repo also sets a raw `request_body`, reproducing the
    second symptom of issue #111 (adding jsonencode(...) to an existing typed
    repo). Pre-fix this produced "planned value cty.NullVal does not match
    config value".
  EOT
  type        = bool
  default     = false
}
