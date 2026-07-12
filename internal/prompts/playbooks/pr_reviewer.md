# Bitbucket PR Reviewer Playbook

This guide instructs you on how to perform a Pull Request review on Bitbucket, combining local code-review findings with remote pull request interactions.

## Parameters
* Pull Request ID: `{{index . "pull_request_id"}}`
* Workspace: `{{index . "workspace"}}` (If empty, derive from local git remote or list repositories)
* Repository Slug: `{{index . "repo_slug"}}` (If empty, derive from local git remote or list repositories)

---

## Steps

### Step 1: Initialize Context & Retrieve Pull Request Metadata
1. Resolve the `workspace` and `repo_slug` if they were not explicitly passed. Check the local git config or use `bitbucket_repositories` operations if needed.
2. Get full details of the Pull Request using `bitbucket_pr` with operation `getAPullRequest` and `pull_request_id`.
3. Fetch all currently existing comments on the PR using `bitbucket_pr` with operation `listCommentsOnAPullRequest`. Keep track of which comments are unresolved/open.

### Step 2: Determine Code Review Path
Check your active chat history and workspace context:

#### Path A: Integrating Local `/review` Findings
If there are already local code-review findings (e.g. from running a local `/review` or code-review subagent under `## Standards` and `## Spec` headings):
1. Analyze the local findings.
2. Reconcile the local findings against the remote comments fetched in Step 1.
3. Identify which findings are new (i.e. not yet covered by a comment on the PR).
4. Ignore any findings that have already been posted or resolved on Bitbucket.

#### Path B: Fallback Two-Axis Review (No `/review` output in context)
If there is no prior code-review output in the context, perform a structured review of the PR directly:
1. Fetch the unified diff of the PR using `bitbucket_pr` with operation `getThePatchForAPullRequest`.
2. Review the diff along **two separate axes**:
   - **Standards:** Check if the changes violate common coding standards or introduce code smells (e.g. Mysterious Name, Duplicated Code, Feature Envy, Primitive Obsession, Speculative Generality).
   - **Spec:** Check if the changes implement the intended requirements or introduce scope creep/logic bugs. Look at PR description, title, commits, and linked issue trackers for spec context.
3. Consolidate your findings into `## Standards` and `## Spec` categories.

### Step 3: Reconcile and Draft Comments
1. For each valid new finding (either from Path A or Path B), draft a clear review comment.
2. If the finding is tied to a specific file and line, make sure you identify:
   - File Path (`inline.path`)
   - Target line number (`inline.to` for additions in the new file, or `inline.from` for deletions in the old file)
3. Present the drafted list of comments to the user for approval. 

### Step 4: Post Comments & Submit Review
1. For each approved comment, create it on Bitbucket using `bitbucket_pr` with operation `createACommentOnAPullRequest`.
2. For inline comments, specify the `inline` object properties:
   - `inline.path`: The relative path to the file.
   - `inline.to` (or `inline.from`): The line number.
   - `content.raw`: The markdown comment text.
3. If appropriate, approve the pull request via `approveAPullRequest` or submit a final summary comment requesting changes.
