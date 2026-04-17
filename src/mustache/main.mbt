///|
enum Node {
  Text(String)
  Variable(String, Bool)
  Section(String, Array[Node], Bool)
  Partial(String)
} derive(Debug, Eq)

///|
pub fn render(template : String, data : Json, partials? : Map[String, String]) -> String {
  let partial_map = match partials {
    Some(p) => p
    None => {}
  }
  let parsed_partials : Map[String, Array[Node]] = {}
  let nodes = parse_template(template)
  render_nodes(nodes, [data], partial_map, parsed_partials)
}

///|
fn parse_template(template : String) -> Array[Node] {
  let (nodes, _, _, _, _) = parse_nodes(template, 0, "{{", "}}", None)
  nodes
}

///|
fn parse_nodes(
  template : String,
  start : Int,
  open : String,
  close : String,
  until : String?,
) -> (Array[Node], Int, String, String, Bool) {
  let mut open = open
  let mut close = close
  let nodes : Array[Node] = []
  let mut pos = start

  while pos < template.length() {
    let next_open = match find_from(template, open, pos) {
      Some(i) => i
      None => {
        nodes.push(Node::Text(template[pos:].to_string()))
        return (nodes, template.length(), open, close, false)
      }
    }

    if next_open > pos {
      nodes.push(Node::Text(template[pos:next_open].to_string()))
    }

    let tag_start = next_open + open.length()

    if open == "{{" && template[tag_start:].has_prefix("{") {
      let content_start = tag_start + 1
      let triple_end = match find_from(template, "}}}", content_start) {
        Some(i) => i
        None => {
          nodes.push(Node::Text(template[next_open:].to_string()))
          return (nodes, template.length(), open, close, false)
        }
      }
      let name = template[content_start:triple_end].to_string().trim().to_string()
      nodes.push(Node::Variable(name, false))
      pos = triple_end + 3
      continue
    }

    let tag_end = match find_from(template, close, tag_start) {
      Some(i) => i
      None => {
        nodes.push(Node::Text(template[next_open:].to_string()))
        return (nodes, template.length(), open, close, false)
      }
    }

    let tag = template[tag_start:tag_end].to_string().trim().to_string()
    pos = tag_end + close.length()

    if tag.is_empty() {
      continue
    }

    let head = match tag.get_char(0) {
      Some(c) => c
      None => continue
    }
    match head {
      '!' => continue
      '&' => {
        nodes.push(Node::Variable(tag[1:].to_string().trim().to_string(), false))
      }
      '#' => {
        let name = tag[1:].to_string().trim().to_string()
        let (children, next_pos, next_open, next_close, _) = parse_nodes(
          template,
          pos,
          open,
          close,
          Some(name),
        )
        nodes.push(Node::Section(name, children, false))
        pos = next_pos
        open = next_open
        close = next_close
      }
      '^' => {
        let name = tag[1:].to_string().trim().to_string()
        let (children, next_pos, next_open, next_close, _) = parse_nodes(
          template,
          pos,
          open,
          close,
          Some(name),
        )
        nodes.push(Node::Section(name, children, true))
        pos = next_pos
        open = next_open
        close = next_close
      }
      '/' => {
        let closing = tag[1:].to_string().trim().to_string()
        match until {
          Some(expected) if closing == expected =>
            return (nodes, pos, open, close, true)
          _ => nodes.push(Node::Text(template[next_open:pos].to_string()))
        }
      }
      '>' => {
        nodes.push(Node::Partial(tag[1:].to_string().trim().to_string()))
      }
      '=' => {
        if tag.has_suffix("=") {
          match parse_delimiters(tag[1:tag.length() - 1].to_string().trim().to_string()) {
            Some((next_open, next_close)) => {
              open = next_open
              close = next_close
            }
            None => ()
          }
        }
      }
      _ => nodes.push(Node::Variable(tag, true))
    }
  }

  (nodes, pos, open, close, false)
}

///|
fn parse_delimiters(input : String) -> (String, String)? {
  let parts = split_whitespace(input)
  match (parts.get(0), parts.get(1)) {
    (Some(open), Some(close)) => Some((open, close))
    _ => None
  }
}

///|
fn split_whitespace(input : String) -> Array[String] {
  let parts : Array[String] = []
  let mut current : Array[Char] = []
  for c in input {
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      if current.length() > 0 {
        parts.push(String::from_array(current))
        current = []
      }
    } else {
      current.push(c)
    }
  }
  if current.length() > 0 {
    parts.push(String::from_array(current))
  }
  parts
}

///|
fn find_from(source : String, needle : String, start : Int) -> Int? {
  if start >= source.length() {
    None
  } else {
    match source[start:].to_string().find(needle) {
      Some(i) => Some(start + i)
      None => None
    }
  }
}

///|
fn render_nodes(
  nodes : Array[Node],
  stack : Array[Json],
  partials : Map[String, String],
  parsed_partials : Map[String, Array[Node]],
) -> String {
  let mut out = ""
  for node in nodes {
    match node {
      Node::Text(text) => out = out + text
      Node::Variable(name, escaped) => {
        let value = match lookup(stack, name) {
          Some(v) => stringify_value(v)
          None => ""
        }
        out = out + (if escaped { escape_html(value) } else { value })
      }
      Node::Section(name, children, inverted) => {
        let value = lookup(stack, name)
        if inverted {
          if is_falsey(value) {
            out = out + render_nodes(children, stack, partials, parsed_partials)
          }
        } else {
          match value {
            Some(Array(items)) => {
              for item in items {
                stack.push(item)
                out = out + render_nodes(children, stack, partials, parsed_partials)
                ignore(stack.pop())
              }
            }
            Some(v) => {
              if is_truthy(v) {
                stack.push(v)
                out = out + render_nodes(children, stack, partials, parsed_partials)
                ignore(stack.pop())
              }
            }
            None => ()
          }
        }
      }
      Node::Partial(name) => {
        match partials.get(name) {
          Some(partial) => {
            let partial_nodes = match parsed_partials.get(name) {
              Some(nodes) => nodes
              None => {
                let parsed = parse_template(partial)
                parsed_partials[name] = parsed
                parsed
              }
            }
            out = out + render_nodes(
              partial_nodes,
              stack,
              partials,
              parsed_partials,
            )
          }
          None => ()
        }
      }
    }
  }
  out
}

///|
fn split_dotted(name : String) -> Array[String] {
  let parts : Array[String] = []
  let mut part : Array[Char] = []
  for c in name {
    if c == '.' {
      parts.push(String::from_array(part))
      part = []
    } else {
      part.push(c)
    }
  }
  parts.push(String::from_array(part))
  parts
}

///|
fn lookup(stack : Array[Json], name : String) -> Json? {
  if name == "." {
    if stack.is_empty() {
      None
    } else {
      stack.get(stack.length() - 1)
    }
  } else {
    let parts = split_dotted(name)
    match parts.get(0) {
      Some(first) => {
        let mut current = resolve_in_stack(stack, first)
        let mut i = 1
        while i < parts.length() {
          current = match (current, parts.get(i)) {
            (Some(Object(obj)), Some(part)) => obj.get(part)
            _ => None
          }
          i += 1
        }
        current
      }
      None => None
    }
  }
}

///|
fn resolve_in_stack(stack : Array[Json], key : String) -> Json? {
  let mut i = stack.length()
  while i > 0 {
    i -= 1
    match stack.get(i) {
      Some(Object(obj)) =>
        match obj.get(key) {
          Some(value) => return Some(value)
          None => ()
        }
      _ => ()
    }
  }
  None
}

///|
fn is_truthy(value : Json) -> Bool {
  match value {
    Null | False => false
    Array(items) => items.length() > 0
    _ => true
  }
}

///|
fn is_falsey(value : Json?) -> Bool {
  match value {
    None => true
    Some(v) => !is_truthy(v)
  }
}

///|
fn stringify_value(value : Json) -> String {
  match value {
    Null => ""
    String(text) => text
    _ => value.stringify()
  }
}

///|
fn escape_html(value : String) -> String {
  value
  .replace_all(old="&", new="&amp;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&#39;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
}
