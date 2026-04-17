# x

[![CI](https://github.com/cogna-dev/x/actions/workflows/ci.yml/badge.svg)](https://github.com/cogna-dev/x/actions/workflows/ci.yml)
[![Publish](https://github.com/cogna-dev/x/actions/workflows/publish.yml/badge.svg)](https://github.com/cogna-dev/x/actions/workflows/publish.yml)
[![Document](https://github.com/cogna-dev/x/actions/workflows/document.yml/badge.svg)](https://github.com/cogna-dev/x/actions/workflows/document.yml)
[![MoonBit](https://img.shields.io/badge/MoonBit-ready-8A2BE2)](https://www.moonbitlang.com/)
[![Version](https://img.shields.io/badge/version-v0.1.3-2ea44f)](https://github.com/cogna-dev/x/releases)

```text
   _________  ____  _   _______    ____  _______ _    __
  / ____/ _ \/ __ \/ | / /   | |  / /\ \/ / ___/| |  / /
 / /   / / / / / / /  |/ / /| | |/ /  \  /\__ \ | | / / 
/ /___/ /_/ / /_/ / /|  / ___ |   /   / /___/ / | |/ /  
\____/\____/\____/_/ |_/_/  |_|_/   /_//____/  |___/   
```

Experimental monorepo for real-world [MoonBit](https://www.moonbitlang.com/) packages.

## Features

- Multiple reusable MoonBit packages in one place
- CI automation for check/build/test
- Publish automation for mooncakes.io
- Documentation workflow support
- Practical parser and schema tooling modules

## Packages

| Package | Description |
|---------|-------------|
| [`cogna-dev/x/hcl`](src/hcl/) | HCL parser built with `cogna-dev/parkit/nom` |
| [`cogna-dev/x/logo`](src/logo/) | Prints the ASCII art for "Cogna" |
| [`cogna-dev/x/mustache`](src/mustache/) | Mustache template renderer with spec-based tests |
| [`cogna-dev/x/sarif`](src/sarif/) | SARIF 2.1.0 static types with JSON encode/decode |

## Development

This repo uses [cogna-dev/moonbit-actions](https://github.com/cogna-dev/moonbit-actions) and the MoonBit skill at `.agents/skills/moonbit`.

```sh
moon check
moon build
moon test
```
