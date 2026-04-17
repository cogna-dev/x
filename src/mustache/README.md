# `cogna-dev/x/mustache`

[![MoonBit](https://img.shields.io/badge/MoonBit-package-6C47FF)](https://www.moonbitlang.com/)
[![Mustache](https://img.shields.io/badge/template-Mustache-111827)](https://mustache.github.io/)
[![Spec](https://img.shields.io/badge/tests-official%20spec-16A34A)](https://github.com/mustache/spec)
[![Status](https://img.shields.io/badge/status-experimental-F59E0B)](../../README.md)

```text
  __  ___          __            __
 /  |/  /_  ______/ /_____ _____/ /_  ___
/ /|_/ / / / / __  / __/ // / _  / _ \/ _ \
/_/  /_/\_,_/\_,_/_/\__\_,_/\_,_/\___/\___/
```

Minimal Mustache rendering for MoonBit with practical, spec-driven behavior.

## Features

- Escaped interpolation: `{{name}}`
- Unescaped interpolation: `{{{name}}}`, `{{&name}}`
- Sections and inverted sections: `{{#x}}...{{/x}}`, `{{^x}}...{{/x}}`
- Dotted-name lookup and implicit iterator (`{{.}}`)
- Comments (`{{! ... }}`)
- Partials (`{{>partial}}`)
- Delimiter switching (`{{= <% %> =}}`)

## Usage

### API

```moonbit
pub fn render(template : String, data : Json, partials? : Map[String, String]) -> String
```

### Basic interpolation

```moonbit
let out = @mustache.render(
  "Hello, {{subject}}!",
  Json::object({ "subject": Json::string("world") }),
)
// out == "Hello, world!"
```

### Sections and dotted names

```moonbit
let template = "{{#person}}{{name}} from {{meta.city}}{{/person}}"
let data = Json::object({
  "person": Json::object({
    "name": Json::string("Joe"),
    "meta": Json::object({ "city": Json::string("Berlin") }),
  }),
})
let out = @mustache.render(template, data)
```

### Partials

```moonbit
let template = "{{>card}}"
let data = Json::object({ "title": Json::string("Hello") })
let partials = { "card": "[{{title}}]" }
let out = @mustache.render(template, data, partials=partials)
// out == "[Hello]"
```

## Specification coverage

This package includes tests adapted from official Mustache spec cases:

- interpolation
- sections
- inverted sections
- comments
- delimiters
- partials

Reference: <https://github.com/mustache/spec>
