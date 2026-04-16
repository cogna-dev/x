package hclgo_test

import (
	"testing"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/zclconf/go-cty/cty"
)

type normBody struct {
	Attributes map[string]any
	Blocks     []normBlock
}

type normBlock struct {
	Type   string
	Labels []string
	Body   normBody
}

func parseNormalized(t *testing.T, src string) normBody {
	t.Helper()
	file, diags := hclsyntax.ParseConfig([]byte(src), "reference.hcl", hcl.InitialPos)
	if diags.HasErrors() {
		t.Fatalf("parse failed: %s", diags.Error())
	}
	body, ok := file.Body.(*hclsyntax.Body)
	if !ok {
		t.Fatalf("unexpected body type %T", file.Body)
	}
	return normalizeBody(t, body)
}

func normalizeBody(t *testing.T, body *hclsyntax.Body) normBody {
	t.Helper()
	attrs := map[string]any{}
	for k, attr := range body.Attributes {
		value, diags := attr.Expr.Value(nil)
		if diags.HasErrors() {
			t.Fatalf("attribute %q eval failed: %s", k, diags.Error())
		}
		attrs[k] = ctyToAny(value)
	}

	blocks := make([]normBlock, 0, len(body.Blocks))
	for _, block := range body.Blocks {
		blocks = append(blocks, normBlock{
			Type:   block.Type,
			Labels: append([]string{}, block.Labels...),
			Body:   normalizeBody(t, block.Body),
		})
	}

	return normBody{Attributes: attrs, Blocks: blocks}
}

func ctyToAny(v cty.Value) any {
	if !v.IsKnown() || v.IsNull() {
		return nil
	}

	switch {
	case v.Type() == cty.String:
		return v.AsString()
	case v.Type() == cty.Bool:
		return v.True()
	case v.Type() == cty.Number:
		bf := v.AsBigFloat()
		f, _ := bf.Float64()
		return f
	case v.Type().IsListType(), v.Type().IsSetType(), v.Type().IsTupleType():
		out := make([]any, 0, v.LengthInt())
		it := v.ElementIterator()
		for it.Next() {
			_, ev := it.Element()
			out = append(out, ctyToAny(ev))
		}
		return out
	case v.Type().IsMapType(), v.Type().IsObjectType():
		out := map[string]any{}
		it := v.ElementIterator()
		for it.Next() {
			k, ev := it.Element()
			out[k.AsString()] = ctyToAny(ev)
		}
		return out
	default:
		return v.GoString()
	}
}

func TestReferenceHashicorpHCL(t *testing.T) {
	t.Run("attributes and nested block", func(t *testing.T) {
		src := `
name = "api"
enabled = true
service "backend" {
  port = 8080
}
`
		got := parseNormalized(t, src)
		expected := normBody{
			Attributes: map[string]any{
				"name":    "api",
				"enabled": true,
			},
			Blocks: []normBlock{
				{
					Type:   "service",
					Labels: []string{"backend"},
					Body: normBody{
						Attributes: map[string]any{"port": 8080.0},
						Blocks:     []normBlock{},
					},
				},
			},
		}
		if diff := diffNormBody(got, expected); diff != "" {
			t.Fatalf("normalized body mismatch:\n%s", diff)
		}
	})

	t.Run("list object and escapes", func(t *testing.T) {
		src := `
numbers = [1, 2, 3]
meta = { env = "prod", replicas = 3 }
escaped = "line\nquote\"ok"
`
		got := parseNormalized(t, src)
		expected := normBody{
			Attributes: map[string]any{
				"numbers": []any{1.0, 2.0, 3.0},
				"meta": map[string]any{
					"env":      "prod",
					"replicas": 3.0,
				},
				"escaped": "line\nquote\"ok",
			},
			Blocks: []normBlock{},
		}
		if diff := diffNormBody(got, expected); diff != "" {
			t.Fatalf("normalized body mismatch:\n%s", diff)
		}
	})

	t.Run("malformed input", func(t *testing.T) {
		_, diags := hclsyntax.ParseConfig([]byte(`service { name = "x"`), "reference.hcl", hcl.InitialPos)
		if !diags.HasErrors() {
			t.Fatal("expected parse diagnostics")
		}
	})
}

func diffNormBody(got, want normBody) string {
	if len(got.Attributes) != len(want.Attributes) {
		return "attribute count differs"
	}
	for k, wv := range want.Attributes {
		gv, ok := got.Attributes[k]
		if !ok {
			return "missing attribute: " + k
		}
		if !deepEqual(gv, wv) {
			return "attribute mismatch: " + k
		}
	}
	if len(got.Blocks) != len(want.Blocks) {
		return "block count differs"
	}
	for i := range want.Blocks {
		gb, wb := got.Blocks[i], want.Blocks[i]
		if gb.Type != wb.Type {
			return "block type mismatch"
		}
		if !deepEqual(gb.Labels, wb.Labels) {
			return "block labels mismatch"
		}
		if nested := diffNormBody(gb.Body, wb.Body); nested != "" {
			return nested
		}
	}
	return ""
}

func deepEqual(a, b any) bool {
	switch av := a.(type) {
	case string:
		bv, ok := b.(string)
		return ok && av == bv
	case bool:
		bv, ok := b.(bool)
		return ok && av == bv
	case float64:
		bv, ok := b.(float64)
		return ok && av == bv
	case nil:
		return b == nil
	case []string:
		bv, ok := b.([]string)
		if !ok || len(av) != len(bv) {
			return false
		}
		for i := range av {
			if av[i] != bv[i] {
				return false
			}
		}
		return true
	case []any:
		bv, ok := b.([]any)
		if !ok || len(av) != len(bv) {
			return false
		}
		for i := range av {
			if !deepEqual(av[i], bv[i]) {
				return false
			}
		}
		return true
	case map[string]any:
		bv, ok := b.(map[string]any)
		if !ok || len(av) != len(bv) {
			return false
		}
		for k, v := range av {
			wv, ok := bv[k]
			if !ok || !deepEqual(v, wv) {
				return false
			}
		}
		return true
	default:
		return false
	}
}
