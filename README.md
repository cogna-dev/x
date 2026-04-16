# x

The experimental monorepo for real-world [MoonBit](https://www.moonbitlang.com/) packages.

## Packages

| Package | Description |
|---------|-------------|
| [`cogna-dev/x/logo`](src/logo/) | Prints the ASCII art for "Cogna" |
| [`cogna-dev/x/sarif`](src/sarif/) | SARIF 2.1.0 static types with JSON encode/decode |

## Development

This repo uses [cogna-dev/moonbit-actions](https://github.com/cogna-dev/moonbit-actions) for CI and the [cogna-dev/moonbit-skill](https://github.com/cogna-dev/moonbit-skill) agent skill (at `.agents/skills/moonbit`).

```sh
# from any package directory (e.g. cogna/)
moon check
moon build
moon test
```
