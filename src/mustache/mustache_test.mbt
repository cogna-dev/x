///|
fn obj(entries : Map[String, Json]) -> Json {
  Json::object(entries)
}

///|
fn arr(items : Array[Json]) -> Json {
  Json::array(items)
}

///|
fn num(value : Double) -> Json {
  Json::number(value)
}

///|
fn str(value : String) -> Json {
  Json::string(value)
}

///|
fn bool(value : Bool) -> Json {
  Json::boolean(value)
}

///|
fn run(template : String, data : Json, expected : String) -> Unit raise Failure {
  let actual = @mustache.render(template, data)
  if actual != expected {
    fail("expected: " + expected + "\nactual: " + actual)
  }
}

///|
fn run_with_partials(
  template : String,
  data : Json,
  expected : String,
  partials : Map[String, String],
) -> Unit raise Failure {
  let actual = @mustache.render(template, data, partials~)
  if actual != expected {
    fail("expected: " + expected + "\nactual: " + actual)
  }
}

///|
test "official interpolation spec cases" {
  // Source: https://github.com/mustache/spec/blob/master/specs/interpolation.json
  run(
    "Hello, {{subject}}!\n",
    obj({ "subject": str("world") }),
    "Hello, world!\n",
  )
  run(
    "These characters should be HTML escaped: {{forbidden}}\n",
    obj({ "forbidden": str("& \" < >") }),
    "These characters should be HTML escaped: &amp; &quot; &lt; &gt;\n",
  )
  run(
    "These characters should not be HTML escaped: {{{forbidden}}}\n",
    obj({ "forbidden": str("& \" < >") }),
    "These characters should not be HTML escaped: & \" < >\n",
  )
  run(
    "\"{{person.name}}\" == \"{{#person}}{{name}}{{/person}}\"",
    obj({ "person": obj({ "name": str("Joe") }) }),
    "\"Joe\" == \"Joe\"",
  )
  run(
    "I ({{cannot}}) be seen!",
    obj({ "cannot": Json::null() }),
    "I () be seen!",
  )
}

///|
test "official sections spec cases" {
  // Source: https://github.com/mustache/spec/blob/master/specs/sections.json
  run(
    "\"{{#boolean}}This should be rendered.{{/boolean}}\"",
    obj({ "boolean": bool(true) }),
    "\"This should be rendered.\"",
  )
  run(
    "\"{{#boolean}}This should not be rendered.{{/boolean}}\"",
    obj({ "boolean": bool(false) }),
    "\"\"",
  )
  run(
    "\"{{#context}}Hi {{name}}.{{/context}}\"",
    obj({ "context": obj({ "name": str("Joe") }) }),
    "\"Hi Joe.\"",
  )
  run(
    "\"{{#list}}{{item}}{{/list}}\"",
    obj({
      "list": arr([
        obj({ "item": num(1) }),
        obj({ "item": num(2) }),
        obj({ "item": num(3) }),
      ]),
    }),
    "\"123\"",
  )
  run(
    "\"{{#list}}({{.}}){{/list}}\"",
    obj({ "list": arr([str("a"), str("b"), str("c")]) }),
    "\"(a)(b)(c)\"",
  )
}

///|
test "official inverted spec cases" {
  // Source: https://github.com/mustache/spec/blob/master/specs/inverted.json
  run(
    "\"{{^boolean}}This should be rendered.{{/boolean}}\"",
    obj({ "boolean": bool(false) }),
    "\"This should be rendered.\"",
  )
  run(
    "\"{{^boolean}}This should not be rendered.{{/boolean}}\"",
    obj({ "boolean": bool(true) }),
    "\"\"",
  )
  run(
    "\"{{^list}}Yay lists!{{/list}}\"",
    obj({ "list": arr([]) }),
    "\"Yay lists!\"",
  )
}

///|
test "official comments and delimiters spec cases" {
  // Sources:
  // - https://github.com/mustache/spec/blob/master/specs/comments.json
  // - https://github.com/mustache/spec/blob/master/specs/delimiters.json
  run("12345{{! Comment Block! }}67890", obj({}), "1234567890")
  run(
    "12345{{!\n  This is a\n  multi-line comment...\n}}67890\n",
    obj({}),
    "1234567890\n",
  )
  run("{{=<% %>=}}(<%text%>)", obj({ "text": str("Hey!") }), "(Hey!)")
}

///|
test "official partials spec cases" {
  // Source: https://github.com/mustache/spec/blob/master/specs/partials.json
  run_with_partials("\"{{>text}}\"", obj({}), "\"from partial\"", {
    "text": "from partial",
  })
  run_with_partials(
    "\"{{>partial}}\"",
    obj({ "text": str("content") }),
    "\"*content*\"",
    { "partial": "*{{text}}*" },
  )
  run_with_partials(
    "{{>outer}}",
    obj({ "a": str("hello"), "b": str("world") }),
    "*hello world!*",
    { "outer": "*{{a}} {{>inner}}*", "inner": "{{b}}!" },
  )
}
