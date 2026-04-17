# `cogna-dev/x/mustache`

A lightweight Mustache template renderer for MoonBit.

## API

```moonbit
pub fn render(template : String, data : Json, partials? : Map[String, String]) -> String
```

- Supports interpolation (`{{name}}`, `{{{name}}}`, `{{&name}}`)
- Supports sections/inverted sections (`{{#name}}...{{/name}}`, `{{^name}}...{{/name}}`)
- Supports comments, partials, dotted names, and delimiter changes

## Tests

This package includes tests adapted from the official Mustache spec:
<https://github.com/mustache/spec>
