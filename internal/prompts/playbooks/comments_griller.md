# Bitbucket PR Comments Griller Playbook

This playbook retrieves all unresolved feedback on a Pull Request and guides you through an interactive grilling session to address and resolve each comment step-by-step.

## Parameters
* Pull Request ID: `{{index . "pull_request_id"}}`
* Workspace: `{{index . "workspace"}}` (If empty, derive from local git remote or list repositories)
* Repository Slug: `{{index . "repo_slug"}}` (If empty, derive from local git remote or list repositories)

---

## Steps

### Step 1: Fetch and Consolidate PR Comments
1. Resolve the `workspace` and `repo_slug` if they were not explicitly passed. Check the local git config or use `bitbucket_repositories` operations if needed.
2. Call `bitbucket_pr` with operation `listCommentsOnAPullRequest` using the `pull_request_id`.
3. Filter out deleted or already resolved comment threads. 
4. Consolidate the active, unresolved comments into a structured, numbered list. For each comment, extract and display:
   - **ID:** The comment ID
   - **Author:** The commenter's name
   - **Location:** File path and line number (if it is an inline comment)
   - **Content:** The raw comment text

### Step 2: Interactive Grilling Loop
Step through each unresolved comment thread one-by-one. For each thread:

1. **Locate the Code:**
   - Find the file and line number referenced in the comment.
   - Read the local source code at that location to understand the current implementation.

2. **Propose Fixes / Options:**
   - Analyze the comment feedback against the local code context.
   - Propose 2-3 concrete, actionable options to resolve the feedback (e.g., Code Fix A, Refactoring Option B, or a justification for ignoring the comment).
   - *Provide your recommended answer first.*

3. **Get User Decision:**
   - Present the comment and your proposed options to the user.
   - **Ask the user for their decision on this comment before moving to the next one.** Asking about multiple comments at once is bewildering. Wait for user feedback.

4. **Apply Fixes & Resolve Thread:**
   - If the user agrees to a fix, use your workspace file-editing tools to apply the changes in the codebase.
   - Run tests to confirm the fix is correct.
   - Invoke `bitbucket_pr` with operation `resolveACommentThread` (using the comment's `id` or thread ID) to mark the comment resolved on Bitbucket.
   - If the user decides to skip or ignore the comment, leave the thread open or reply explaining the reasoning using `createACommentOnAPullRequest` (setting `parent.id` to the comment ID).

### Step 3: Loop and Finalize
* Repeat Step 2 for all open comment threads until all are processed.
* Once the list is exhausted, summarize the changes made and any decisions recorded.
