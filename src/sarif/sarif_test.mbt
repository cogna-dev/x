///|
test "parse and stringify minimal SARIF log" {
  let source =
    #|{
    #|  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
    #|  "version": "2.1.0",
    #|  "runs": [
    #|    {
    #|      "tool": {
    #|        "driver": {
    #|          "name": "demo-linter",
    #|          "semanticVersion": "1.2.3",
    #|          "rules": [
    #|            {
    #|              "id": "RULE001",
    #|              "shortDescription": { "text": "Avoid dangerous API" }
    #|            }
    #|          ]
    #|        }
    #|      },
    #|      "results": [
    #|        {
    #|          "ruleId": "RULE001",
    #|          "level": "warning",
    #|          "message": { "text": "Potential issue" },
    #|          "locations": [
    #|            {
    #|              "physicalLocation": {
    #|                "artifactLocation": { "uri": "src/main.mbt" },
    #|                "region": { "startLine": 12, "startColumn": 3 }
    #|              }
    #|            }
    #|          ]
    #|        }
    #|      ]
    #|    }
    #|  ]
    #|}
  let log = @sarif.parse(source)
  inspect(log.version, content="2.1.0")
  inspect(log.schema, content="Some(\"https://json.schemastore.org/sarif-2.1.0.json\")")
  inspect(log.runs.length(), content="1")
  let run = log.runs[0]
  inspect(run.tool.driver.name, content="demo-linter")
  let result = run.results.unwrap()[0]
  inspect(result.rule_id, content="Some(\"RULE001\")")
  inspect(result.level, content="Some(Warning)")
  let location = result.locations.unwrap()[0]
  inspect(
    location.physical_location.unwrap().artifact_location.unwrap().uri,
    content="Some(\"src/main.mbt\")",
  )
  let rendered = @sarif.stringify(log)
  let parsed_again = @sarif.parse(rendered)
  inspect(parsed_again == log, content="true")
}

///|
test "invalid result level returns decode error" {
  let source =
    #|{
    #|  "version": "2.1.0",
    #|  "runs": [
    #|    {
    #|      "tool": { "driver": { "name": "x" } },
    #|      "results": [
    #|        {
    #|          "level": "critical",
    #|          "message": { "text": "oops" }
    #|        }
    #|      ]
    #|    }
    #|  ]
    #|}
  let result = try? @sarif.parse(source)
  inspect(result is Err(_), content="true")
}
