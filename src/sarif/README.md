# `cogna-dev/x/sarif`

[![MoonBit](https://img.shields.io/badge/MoonBit-ready-7A4CFF)](https://www.moonbitlang.com/)
[![SARIF](https://img.shields.io/badge/SARIF-2.1.0-0A7EA4)](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
[![Repository](https://img.shields.io/badge/cogna--dev%2Fx-monorepo-1F2937)](https://github.com/cogna-dev/x)

```text
   _____    _    ____  ___ _____
  / ____|  / \  |  _ \|_ _|  ___|
 | (___   / _ \ | |_) || || |_
  \___ \ / ___ \|  _ < | ||  _|
  ____) /_/   \_\_| \_\___|_|

  2.1.0 | Static MoonBit Types | JSON Encode/Decode
```

MoonBit SARIF package for **typed modeling**, **strict decoding**, and
**predictable encoding** of SARIF 2.1.0 logs.

## Highlights

- Static types for key SARIF entities (`SarifLog`, `Run`, `Result`, `Location`, etc.)
- `FromJson` + `ToJson` implementations for round-trip workflows
- Strict enum decoding for `ResultLevel` (`none`, `note`, `warning`, `error`)
- Convenient top-level API:
  - `@sarif.parse(json_string)`
  - `@sarif.stringify(log, indent=2)`

## Installation / Import

In MoonBit package configuration:

```moonbit
import {
  "cogna-dev/x/sarif" @sarif,
}
```

## Core API

```moonbit
pub fn parse(s : String) -> SarifLog raise ParseSarifError
pub fn stringify(log : SarifLog, indent? : Int) -> String
```

### Error model

`ParseSarifError` distinguishes:

- `JsonParse`: invalid JSON syntax
- `JsonDecode`: valid JSON that does not match SARIF structure/types

## Quick start

```moonbit
let source =
  #|{
  #|  "version": "2.1.0",
  #|  "runs": [
  #|    {
  #|      "tool": { "driver": { "name": "demo-linter" } },
  #|      "results": [
  #|        {
  #|          "ruleId": "RULE001",
  #|          "level": "warning",
  #|          "message": { "text": "Potential issue" }
  #|        }
  #|      ]
  #|    }
  #|  ]
  #|}

let log = @sarif.parse(source)
let pretty = @sarif.stringify(log, indent=2)
```

## What is modeled

This package currently includes practical SARIF structures commonly needed for
analysis pipelines, including:

- log/run/tool metadata
- driver rules (`ReportingDescriptor`)
- results/messages/locations/regions
- artifacts and artifact content
- invocation and VCS provenance details
- custom `properties` bags via `Map[String, Json]?`

## Typical usage patterns

### 1) Ingest analyzer output

Parse raw SARIF JSON into typed values and inspect fields safely.

### 2) Transform logs

Read, mutate specific fields (e.g., tool metadata, message text), then encode
back to SARIF JSON.

### 3) Validate producer output

Use strict decode to catch schema/type mismatches early in CI or local checks.

## Related

- SARIF 2.1.0 specification:
  <https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html>
- Repository root docs: <https://github.com/cogna-dev/x>
