///|
/// HCL parse errors from `parse`.
pub suberror ParseHclError {
  Nom(@nom.ParseError)
  TrailingInput(String)
} derive(Show)

///|
/// Parse HCL text into a typed `Document`.
pub fn parse(input : String) -> Document raise ParseHclError {
  match parse_body_until(input, false) {
    Ok((rest, body)) => {
      let remaining = skip_trivia(rest)
      if remaining.length() == 0 {
        { body, }
      } else {
        raise ParseHclError::TrailingInput(remaining)
      }
    }
    Err(e) => raise ParseHclError::Nom(e)
  }
}

///|
fn skip_trivia(input : String) -> String {
  let mut remaining = input
  while true {
    let (next, _) = match @nom.multispace0().parse(remaining) {
      Ok(v) => v
      Err(_) => (remaining, "")
    }
    remaining = next
    if remaining.has_prefix("#") {
      remaining = skip_line_comment(remaining[1:].to_string())
      continue
    }
    if remaining.has_prefix("//") {
      remaining = skip_line_comment(remaining[2:].to_string())
      continue
    }
    break
  }
  remaining
}

///|
fn skip_line_comment(input : String) -> String {
  let mut i = 0
  while i < input.length() {
    let c = match input.get_char(i) {
      Some(c) => c
      None => return ""
    }
    if c == '\n' {
      return input[i + 1:].to_string()
    }
    i += 1
  }
  ""
}

///|
fn is_ident_start(c : Char) -> Bool {
  @nom.is_alpha(c) || c == '_'
}

///|
fn is_ident_continue(c : Char) -> Bool {
  @nom.is_alphanumeric(c) || c == '_' || c == '-'
}

///|
fn identifier_parser() -> @nom.Parser[String] {
  @nom.Parser::new(fn(input) {
    match @nom.satisfy(is_ident_start).parse(input) {
      Err(e) => Err(e)
      Ok((rest1, first)) =>
        match @nom.take_while(is_ident_continue).parse(rest1) {
          Ok((rest2, tail)) => Ok((rest2, String::make(1, first) + tail))
          Err(e) => Err(e)
        }
    }
  })
}

///|
fn string_parser() -> @nom.Parser[String] {
  @nom.Parser::new(fn(input) {
    let (rest_open, _) = match @nom.char_('"').parse(input) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    let mut i = 0
    let mut escaped = false
    let mut out = ""
    while i < rest_open.length() {
      let c = match rest_open.get_char(i) {
        Some(c) => c
        None =>
          return Err(
            @nom.ParseError::new(rest_open, "unterminated string literal"),
          )
      }
      if escaped {
        let decoded = match c {
          '"' => "\""
          '\\' => "\\"
          'n' => "\n"
          'r' => "\r"
          't' => "\t"
          _ =>
            return Err(
              @nom.ParseError::new(rest_open, "invalid escape sequence"),
            )
        }
        out = out + decoded
        escaped = false
        i += 1
        continue
      }
      if c == '\\' {
        escaped = true
        i += 1
        continue
      }
      if c == '"' {
        return Ok((rest_open[i + 1:].to_string(), out))
      }
      if c == '\n' || c == '\r' {
        return Err(
          @nom.ParseError::new(rest_open, "unterminated string literal"),
        )
      }
      out = out + String::make(1, c)
      i += 1
    }
    Err(@nom.ParseError::new(rest_open, "unterminated string literal"))
  })
}

///|
fn key_parser() -> @nom.Parser[String] {
  @nom.alt([string_parser(), identifier_parser()])
}

///|
fn parse_value(input : String) -> @nom.IResult[Expression] {
  let source = skip_trivia(input)

  match
    @nom.map(string_parser(), fn(v) { Expression::String(v) }).parse(source) {
    Ok(v) => return Ok(v)
    Err(_) => ()
  }

  match @nom.map(@nom.double(), fn(v) { Expression::Number(v) }).parse(source) {
    Ok(v) => return Ok(v)
    Err(_) => ()
  }

  match parse_list(source) {
    Ok(v) => return Ok(v)
    Err(_) => ()
  }

  match parse_object(source) {
    Ok(v) => return Ok(v)
    Err(_) => ()
  }

  match identifier_parser().parse(source) {
    Ok((rest, ident)) =>
      match ident {
        "true" => Ok((rest, Expression::Bool(true)))
        "false" => Ok((rest, Expression::Bool(false)))
        "null" => Ok((rest, Expression::Null))
        _ => Ok((rest, Expression::Identifier(ident)))
      }
    Err(e) => Err(e)
  }
}

///|
fn parse_list(input : String) -> @nom.IResult[Expression] {
  match @nom.char_('[').parse(input) {
    Err(e) => Err(e)
    Ok((rest_open, _)) => {
      let values : Array[Expression] = []
      let mut rest = skip_trivia(rest_open)
      match @nom.char_(']').parse(rest) {
        Ok((rest_close, _)) => return Ok((rest_close, Expression::List(values)))
        Err(_) => ()
      }
      while true {
        let (next, value) = match parse_value(rest) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        values.push(value)
        rest = skip_trivia(next)
        match @nom.char_(',').parse(rest) {
          Ok((after_comma, _)) => {
            rest = skip_trivia(after_comma)
            continue
          }
          Err(_) => ()
        }
        match @nom.char_(']').parse(rest) {
          Ok((rest_close, _)) =>
            return Ok((rest_close, Expression::List(values)))
          Err(e) => return Err(e)
        }
      }
      Err(@nom.ParseError::new(rest, "expected list terminator"))
    }
  }
}

///|
fn parse_object(input : String) -> @nom.IResult[Expression] {
  match @nom.char_('{').parse(input) {
    Err(e) => Err(e)
    Ok((rest_open, _)) => {
      let entries : Map[String, Expression] = {}
      let mut rest = skip_trivia(rest_open)
      match @nom.char_('}').parse(rest) {
        Ok((rest_close, _)) =>
          return Ok((rest_close, Expression::Object(entries)))
        Err(_) => ()
      }

      while true {
        let (rest_key, key) = match key_parser().parse(rest) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        let rest_eq = skip_trivia(rest_key)
        let (rest_after_eq, _) = match @nom.char_('=').parse(rest_eq) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        let (rest_value, value) = match parse_value(rest_after_eq) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        entries[key] = value
        rest = skip_trivia(rest_value)
        match @nom.char_(',').parse(rest) {
          Ok((after_comma, _)) => {
            rest = skip_trivia(after_comma)
            continue
          }
          Err(_) => ()
        }
        match @nom.char_('}').parse(rest) {
          Ok((rest_close, _)) =>
            return Ok((rest_close, Expression::Object(entries)))
          Err(e) => return Err(e)
        }
      }
      Err(@nom.ParseError::new(rest, "expected object terminator"))
    }
  }
}

///|
fn parse_item(input : String) -> @nom.IResult[BodyItem] {
  let source = skip_trivia(input)
  let (rest_head, item_type) = match identifier_parser().parse(source) {
    Ok(v) => v
    Err(e) => return Err(e)
  }

  let mut rest = skip_trivia(rest_head)
  match @nom.char_('=').parse(rest) {
    Ok((after_eq, _)) => {
      let (next, value) = match parse_value(after_eq) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      Ok((next, BodyItem::Attribute({ key: item_type, value })))
    }
    Err(_) => {
      let labels : Array[String] = []
      while true {
        rest = skip_trivia(rest)
        match @nom.char_('{').parse(rest) {
          Ok((after_open, _)) => {
            let (after_body, body) = match parse_body_until(after_open, true) {
              Ok(v) => v
              Err(e) => return Err(e)
            }
            return Ok(
              (after_body, BodyItem::Block({ type_: item_type, labels, body })),
            )
          }
          Err(_) => ()
        }

        match key_parser().parse(rest) {
          Ok((after_label, label)) => {
            labels.push(label)
            rest = after_label
          }
          Err(_) =>
            return Err(@nom.ParseError::new(rest, "expected '=' or block body"))
        }
      }
      Err(@nom.ParseError::new(rest, "expected block body"))
    }
  }
}

///|
fn parse_body_until(input : String, until_end : Bool) -> @nom.IResult[Body] {
  let items : Array[BodyItem] = []
  let mut rest = skip_trivia(input)

  while true {
    rest = skip_trivia(rest)
    if until_end {
      match @nom.char_('}').parse(rest) {
        Ok((after_close, _)) => return Ok((after_close, { items, }))
        Err(_) => ()
      }
    } else if rest.length() == 0 {
      return Ok((rest, { items, }))
    }

    if until_end && rest.length() == 0 {
      return Err(@nom.ParseError::new(rest, "unexpected end of input"))
    }

    let (next, item) = match parse_item(rest) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    items.push(item)
    rest = next
  } nobreak {
    Ok((rest, { items, }))
  }
}
