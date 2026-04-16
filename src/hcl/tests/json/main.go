package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/zclconf/go-cty/cty"
)

type fixture struct {
	Name  string
	Input string
}

type parseResult struct {
	Ok    bool `json:"ok"`
	Value any  `json:"value,omitempty"`
}

var fixtures = []fixture{
	{
		Name: "attributes_and_block",
		Input: `
name = "api"
enabled = true
service "backend" {
  port = 8080
}
`,
	},
	{
		Name: "list_object_and_escapes",
		Input: `
numbers = [1, 2, 3]
meta = { env = "prod", replicas = 3 }
escaped = "line\\nquote\\\"ok"
`,
	},
	{
		Name:  "malformed",
		Input: `service { name = "x"`,
	},
}

func main() {
	moonResults, err := runMoonHarness()
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to run moon harness: %v\n", err)
		os.Exit(1)
	}

	hashicorpResults := map[string]parseResult{}
	for _, tc := range fixtures {
		hashicorpResults[tc.Name] = parseWithHashicorp(tc.Input)
	}

	if !reflect.DeepEqual(moonResults, hashicorpResults) {
		fmt.Fprintln(os.Stderr, "mismatch between cogna-dev/x/hcl and hashicorp/hcl results")
		moonJSON, _ := json.MarshalIndent(moonResults, "", "  ")
		hclJSON, _ := json.MarshalIndent(hashicorpResults, "", "  ")
		fmt.Fprintf(os.Stderr, "moon:\n%s\n", string(moonJSON))
		fmt.Fprintf(os.Stderr, "hashicorp:\n%s\n", string(hclJSON))
		os.Exit(1)
	}

	fmt.Println("results match")
}

func runMoonHarness() (map[string]parseResult, error) {
	cmd := exec.Command("moon", "run", "src/hcl/tests/json/moon")
	cmd.Dir = repoRoot()
	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("%w\n%s", err, string(output))
	}
	start := bytes.IndexByte(output, '{')
	if start == -1 {
		return nil, fmt.Errorf("moon output missing json payload: %s", string(output))
	}
	output = output[start:]

	out := map[string]parseResult{}
	if err := json.Unmarshal(output, &out); err != nil {
		return nil, fmt.Errorf("unmarshal moon json: %w\nraw: %s", err, string(output))
	}
	return out, nil
}

func repoRoot() string {
	wd, err := os.Getwd()
	if err != nil {
		return "."
	}
	dir := filepath.Clean(wd)
	for {
		if _, err := os.Stat(filepath.Join(dir, "moon.mod.json")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return wd
		}
		dir = parent
	}
}

func parseWithHashicorp(src string) parseResult {
	file, diags := hclsyntax.ParseConfig([]byte(src), "fixture.hcl", hcl.InitialPos)
	if diags.HasErrors() {
		return parseResult{Ok: false}
	}
	body, ok := file.Body.(*hclsyntax.Body)
	if !ok {
		return parseResult{Ok: false}
	}
	return parseResult{Ok: true, Value: normalizeBody(body)}
}

func normalizeBody(body *hclsyntax.Body) map[string]any {
	attributes := map[string]any{}
	for _, attr := range body.Attributes {
		value, diags := attr.Expr.Value(nil)
		if diags.HasErrors() {
			attributes[attr.Name] = map[string]any{"kind": "invalid"}
			continue
		}
		attributes[attr.Name] = ctyToNormExpr(value)
	}

	blocks := make([]any, 0, len(body.Blocks))
	for _, block := range body.Blocks {
		labels := make([]any, 0, len(block.Labels))
		for _, label := range block.Labels {
			labels = append(labels, label)
		}
		blocks = append(blocks, map[string]any{
			"type":   block.Type,
			"labels": labels,
			"body":   normalizeBody(block.Body),
		})
	}

	return map[string]any{"attributes": attributes, "blocks": blocks}
}

func ctyToNormExpr(v cty.Value) map[string]any {
	if !v.IsKnown() {
		return map[string]any{"kind": "invalid"}
	}
	if v.IsNull() {
		return map[string]any{"kind": "null"}
	}

	switch {
	case v.Type() == cty.String:
		return map[string]any{"kind": "string", "value": v.AsString()}
	case v.Type() == cty.Bool:
		return map[string]any{"kind": "bool", "value": v.True()}
	case v.Type() == cty.Number:
		f, _ := v.AsBigFloat().Float64()
		return map[string]any{"kind": "number", "value": f}
	case v.Type().IsListType(), v.Type().IsSetType(), v.Type().IsTupleType():
		values := make([]any, 0, v.LengthInt())
		it := v.ElementIterator()
		for it.Next() {
			_, ev := it.Element()
			values = append(values, ctyToNormExpr(ev))
		}
		return map[string]any{"kind": "list", "value": values}
	case v.Type().IsMapType(), v.Type().IsObjectType():
		values := map[string]any{}
		it := v.ElementIterator()
		for it.Next() {
			k, ev := it.Element()
			values[k.AsString()] = ctyToNormExpr(ev)
		}
		return map[string]any{"kind": "object", "value": values}
	default:
		return map[string]any{"kind": "invalid"}
	}
}
