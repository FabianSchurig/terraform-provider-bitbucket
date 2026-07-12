# Domain Context: Bitbucket MCP Playbooks

This document defines the domain model and glossary for the Model Context Protocol (MCP) playbooks offered by the Bitbucket MCP server (`bb-mcp`).

## Glossary

### Playbook
A markdown-based template registered in `bb-mcp` that guides an LLM through a specific multi-step workflow using MCP tools.

### PR Reviewer Playbook (`bitbucket_pr_reviewer`)
An MCP playbook that takes local code-review findings (e.g., from Matt Pocock's `/review` skill) and helps the LLM reconcile, post, and manage them on the remote Bitbucket Pull Request. 
* If no local review findings are present in the chat context, it runs a fallback code review along two axes: **Standards** and **Spec**.

### PR Comments Griller Playbook (`bitbucket_comments_griller`)
An MCP playbook that retrieves all unresolved comments from a Bitbucket Pull Request and guides the user through an interactive, step-by-step grilling session to address and resolve each comment.

### Prompt Argument
Programmatic variables (such as `pull_request_id`, `workspace`, and `repo_slug`) defined in the MCP schema that the host client resolves and passes to the server at runtime.

## Core Workflows

### 1. PR Reviewer Flow
1. **Analyze Local Context:** Check if local review findings (under `## Standards` and `## Spec`) are present in the chat context.
2. **Fetch Patch (Fallback only):** If no local findings exist, fetch the unified patch/diff for the PR via `getThePatchForAPullRequest` and run a two-axis review (Standards vs. Spec).
3. **Fetch Bitbucket Comments:** Retrieve existing comments via `listCommentsOnAPullRequest`.
4. **Reconcile:** Match findings with remote comments to avoid duplication.
5. **Post Comments:** Present draft comments to the user for approval, then post them using `createACommentOnAPullRequest`.

### 2. PR Comments Griller Flow
1. **Fetch Open Comments:** Retrieve comments via `listCommentsOnAPullRequest` and filter for unresolved threads.
2. **Consolidate:** Present a numbered, structured list of all open comments.
3. **Grill and Resolve:** Step through each comment one-by-one:
   - Propose 2-3 code fixes or actions.
   - Prompt the user to choose (Apply fix, Ignore/Skip, or Discuss).
   - Edit the codebase as decided.
   - Resolve the comment thread on Bitbucket via `resolveACommentThread`.
