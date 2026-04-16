///|
struct Case {
  name : String
  input : String
}

///|
fn fixture_cases() -> Array[Case] {
  [
    {
      name: "attributes_and_block",
      input: (
        #|name = "api"
        #|enabled = true
        #|service "backend" {
        #|  port = 8080
        #|}
      ),
    },
    {
      name: "list_object_and_escapes",
      input: (
        #|numbers = [1, 2, 3]
        #|meta = { env = "prod", replicas = 3 }
        #|escaped = "line\\nquote\\\"ok"
      ),
    },
    { name: "malformed", input: "service { name = \"x\"" },
  ]
}

///|
fn bool_json(v : Bool) -> Json {
  v.to_json()
}

///|
fn expr_json(expr : @hcl.Expression) -> Json {
  let out : Map[String, Json] = {}
  match expr {
    @hcl.Expression::String(v) => {
      out["kind"] = "string".to_json()
      out["value"] = v.to_json()
    }
    @hcl.Expression::Number(v) => {
      out["kind"] = "number".to_json()
      out["value"] = v.to_json()
    }
    @hcl.Expression::Bool(v) => {
      out["kind"] = "bool".to_json()
      out["value"] = bool_json(v)
    }
    @hcl.Expression::Null => out["kind"] = "null".to_json()
    @hcl.Expression::List(values) => {
      out["kind"] = "list".to_json()
      let arr : Array[Json] = []
      for value in values {
        arr.push(expr_json(value))
      }
      out["value"] = arr.to_json()
    }
    @hcl.Expression::Object(entries) => {
      out["kind"] = "object".to_json()
      let obj : Map[String, Json] = {}
      for key, value in entries {
        obj[key] = expr_json(value)
      }
      out["value"] = obj.to_json()
    }
    @hcl.Expression::Identifier(v) => {
      out["kind"] = "invalid".to_json()
      out["value"] = v.to_json()
    }
  }
  out.to_json()
}

///|
fn body_json(body : @hcl.Body) -> Json {
  let attributes : Map[String, Json] = {}
  let blocks : Array[Json] = []

  for item in body.items {
    match item {
      @hcl.BodyItem::Attribute(attr) =>
        attributes[attr.key] = expr_json(attr.value)
      @hcl.BodyItem::Block(block) => {
        let out : Map[String, Json] = {}
        out["type"] = block.type_.to_json()
        let labels : Array[Json] = []
        for label in block.labels {
          labels.push(label.to_json())
        }
        out["labels"] = labels.to_json()
        out["body"] = body_json(block.body)
        blocks.push(out.to_json())
      }
    }
  }

  let out : Map[String, Json] = {
    "attributes": attributes.to_json(),
    "blocks": blocks.to_json(),
  }
  out.to_json()
}

///|
fn main {
  let results : Map[String, Json] = {}
  for tc in fixture_cases() {
    let parsed = try? @hcl.parse(tc.input)
    let out : Map[String, Json] = {}
    match parsed {
      Ok(doc) => {
        out["ok"] = true.to_json()
        out["value"] = body_json(doc.body)
      }
      Err(_) => out["ok"] = false.to_json()
    }
    results[tc.name] = out.to_json()
  }

  println(results.to_json().stringify())
}
