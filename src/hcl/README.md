# `cogna-dev/x/hcl`

[![MoonBit](https://img.shields.io/badge/MoonBit-package-6C47FF)](https://www.moonbitlang.com/)
[![Parser](https://img.shields.io/badge/parser-typed%20AST-0EA5E9)](#features)
[![Combinators](https://img.shields.io/badge/built%20with-cogna--dev%2Fparkit%2Fnom-14B8A6)](https://github.com/cogna-dev/parkit)
[![Status](https://img.shields.io/badge/status-experimental-F59E0B)](../../README.md)

```text
██╗  ██╗ ██████╗██╗     
██║  ██║██╔════╝██║     
███████║██║     ██║     
██╔══██║██║     ██║     
██║  ██║╚██████╗███████╗
╚═╝  ╚═╝ ╚═════╝╚══════╝
```

Typed HCL syntax parser for MoonBit, implemented with `cogna-dev/parkit/nom`.

## Features

- Typed AST (`Document`, `Body`, `BodyItem`, `Attribute`, `Block`, `Expression`)
- Attributes: `key = value`
- Blocks with labels: `type "label" { ... }`
- Nested bodies (recursive block parsing)
- Expressions:
  - string
  - number
  - bool
  - null
  - list
  - object
  - identifier
- Line comments: `# ...` and `// ...`
- Escaped strings: `\"`, `\\`, `\n`, `\r`, `\t`
- Explicit parse error type: `ParseHclError`

## Usage

```moonbit
let input =
  #|service "backend" {
  #|  port = 8080
  #|  enabled = true
  #|  tags = ["api", "edge"]
  #|}

match @hcl.parse(input) {
  Ok(doc) => {
    // doc.body.items is a typed syntax tree
    ignore(doc)
  }
  Err(e) => {
    // parse error
    ignore(e)
  }
}
```

## AST at a glance

- `Document` → root HCL document
- `Body` → sequence of `BodyItem`
- `BodyItem` → `Attribute` or `Block`
- `Attribute` → `name` + `Expression` + `pos` (`line`, `col`)
- `Block` → `type_` + `labels` + nested `Body` + `pos` (`line`, `col`)
- `Expression` → scalar/collection/identifier node kinds

## Notes

- This package focuses on **syntax structure parsing**.
- It does **not** perform `hcldec`-style decoding/semantic resolution.
