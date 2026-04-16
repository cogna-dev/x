///|
test "parse attributes and block" {
  let input =
    #|name = "api"
    #|enabled = true
    #|service "backend" {
    #|  port = 8080
    #|}
  let doc = @hcl.parse(input)
  inspect(doc.body.items.length(), content="3")

  guard doc.body.items[0] is @hcl.BodyItem::Attribute(attr0) else {
    fail("expected attribute")
  }
  inspect(attr0.key, content="name")
  inspect(attr0.value, content="String(\"api\")")

  guard doc.body.items[2] is @hcl.BodyItem::Block(block) else {
    fail("expected block")
  }
  inspect(block.type_, content="service")
  inspect(block.labels, content="[\"backend\"]")
  inspect(block.body.items.length(), content="1")
}

///|
test "parse list and object values" {
  let input =
    #|numbers = [1, 2, 3]
    #|meta = { env = "prod", replicas = 3 }
  let doc = @hcl.parse(input)

  guard doc.body.items[0] is @hcl.BodyItem::Attribute(numbers) else {
    fail("expected numbers attribute")
  }
  guard numbers.value is @hcl.Expression::List(values) else {
    fail("expected list")
  }
  inspect(values.length(), content="3")

  guard doc.body.items[1] is @hcl.BodyItem::Attribute(meta) else {
    fail("expected meta attribute")
  }
  guard meta.value is @hcl.Expression::Object(entries) else {
    fail("expected object")
  }
  inspect(entries.contains("env"), content="true")
  inspect(entries.contains("replicas"), content="true")
}

///|
test "parse error on malformed input" {
  let result = try? @hcl.parse("service { name = \"x\"")
  inspect(result is Err(_), content="true")
}
