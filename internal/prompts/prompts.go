// Package prompts provides MCP prompt handlers (playbooks) for the Bitbucket
// MCP server. Playbooks are embedded markdown files that give LLMs step-by-step
// instructions for common workflows.
package prompts

import (
	"bytes"
	"context"
	"embed"
	"text/template"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

//go:embed playbooks/*.md
var playbooks embed.FS

// playbook defines a single MCP prompt backed by an embedded markdown file.
type playbook struct {
	Name        string
	Description string
	File        string // path within the embedded FS
}

var allPlaybooks = []playbook{
	{
		Name:        "bitbucket_pr_reviewer",
		Description: "A step-by-step guide to reviewing a pull request on Bitbucket (integrates with /review skill).",
		File:        "playbooks/pr_reviewer.md",
	},
	{
		Name:        "bitbucket_comments_griller",
		Description: "Retrieve all unresolved comments on a Pull Request and run a /grill-with-docs session to resolve them.",
		File:        "playbooks/comments_griller.md",
	},
}

var promptArgs = []*mcp.PromptArgument{
	{
		Name:        "pull_request_id",
		Description: "The ID of the pull request on Bitbucket.",
		Required:    true,
	},
	{
		Name:        "workspace",
		Description: "The Bitbucket workspace name. If omitted, it will be derived from git remote or local context.",
		Required:    false,
	},
	{
		Name:        "repo_slug",
		Description: "The repository slug. If omitted, it will be derived from git remote or local context.",
		Required:    false,
	},
}

// Register adds all playbook prompts to the MCP server.
func Register(server *mcp.Server) {
	for _, pb := range allPlaybooks {
		pb := pb // capture loop variable
		server.AddPrompt(&mcp.Prompt{
			Name:        pb.Name,
			Description: pb.Description,
			Arguments:   promptArgs,
		}, promptHandler(pb))
	}
}

func promptHandler(pb playbook) mcp.PromptHandler {
	return func(_ context.Context, req *mcp.GetPromptRequest) (*mcp.GetPromptResult, error) {
		data, err := playbooks.ReadFile(pb.File)
		if err != nil {
			return nil, err
		}

		tmpl, err := template.New(pb.Name).Parse(string(data))
		if err != nil {
			return nil, err
		}

		var args map[string]string
		if req.Params != nil {
			args = req.Params.Arguments
		}

		var buf bytes.Buffer
		err = tmpl.Execute(&buf, args)
		if err != nil {
			return nil, err
		}

		return &mcp.GetPromptResult{
			Description: pb.Description,
			Messages: []*mcp.PromptMessage{
				{
					Role:    "user",
					Content: &mcp.TextContent{Text: buf.String()},
				},
			},
		}, nil
	}
}
