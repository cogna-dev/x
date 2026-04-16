// Black-box tests for cogna-dev/x/openapi
// Uses a minimal subset of the Petstore 3.1 JSON spec.

///|
test "parse minimal petstore" {
  let json =
    #|{
    #|  "openapi": "3.1.0",
    #|  "info": {
    #|    "title": "Petstore",
    #|    "version": "1.0.0",
    #|    "description": "A sample API"
    #|  },
    #|  "paths": {
    #|    "/pets": {
    #|      "get": {
    #|        "summary": "List all pets",
    #|        "operationId": "listPets",
    #|        "tags": ["pets"],
    #|        "parameters": [
    #|          {
    #|            "name": "limit",
    #|            "in": "query",
    #|            "required": false,
    #|            "schema": { "type": "integer" }
    #|          }
    #|        ],
    #|        "responses": {
    #|          "200": {
    #|            "description": "A list of pets",
    #|            "content": {
    #|              "application/json": {
    #|                "schema": {
    #|                  "type": "array",
    #|                  "items": { "$ref": "#/components/schemas/Pet" }
    #|                }
    #|              }
    #|            }
    #|          }
    #|        }
    #|      },
    #|      "post": {
    #|        "summary": "Create a pet",
    #|        "operationId": "createPet",
    #|        "tags": ["pets"],
    #|        "requestBody": {
    #|          "required": true,
    #|          "content": {
    #|            "application/json": {
    #|              "schema": { "$ref": "#/components/schemas/NewPet" }
    #|            }
    #|          }
    #|        },
    #|        "responses": {
    #|          "201": { "description": "Null response" }
    #|        }
    #|      }
    #|    },
    #|    "/pets/{petId}": {
    #|      "get": {
    #|        "summary": "Info for a specific pet",
    #|        "operationId": "showPetById",
    #|        "tags": ["pets"],
    #|        "parameters": [
    #|          {
    #|            "name": "petId",
    #|            "in": "path",
    #|            "required": true,
    #|            "schema": { "type": "string" }
    #|          }
    #|        ],
    #|        "responses": {
    #|          "200": {
    #|            "description": "Expected response",
    #|            "content": {
    #|              "application/json": {
    #|                "schema": { "$ref": "#/components/schemas/Pet" }
    #|              }
    #|            }
    #|          },
    #|          "default": {
    #|            "description": "unexpected error"
    #|          }
    #|        }
    #|      }
    #|    }
    #|  },
    #|  "components": {
    #|    "schemas": {
    #|      "Pet": {
    #|        "type": "object",
    #|        "required": ["id", "name"],
    #|        "properties": {
    #|          "id":   { "type": "integer" },
    #|          "name": { "type": "string" },
    #|          "tag":  { "type": "string" }
    #|        }
    #|      },
    #|      "NewPet": {
    #|        "type": "object",
    #|        "required": ["name"],
    #|        "properties": {
    #|          "name": { "type": "string" },
    #|          "tag":  { "type": "string" }
    #|        }
    #|      }
    #|    }
    #|  }
    #|}
  let doc = @openapi.parse(json)
  inspect(doc.openapi, content=(
    #|3.1.0
  ))
  inspect(doc.info.title, content=(
    #|Petstore
  ))
  inspect(doc.info.version, content=(
    #|1.0.0
  ))
  // paths exist
  let paths = doc.paths.unwrap()
  inspect(paths.contains("/pets"), content="true")
  inspect(paths.contains("/pets/{petId}"), content="true")
  // GET /pets has the right operation id
  let pets_path = paths["/pets"]
  let list_op = pets_path.get.unwrap()
  inspect(list_op.operation_id, content="Some(\"listPets\")")
  inspect(list_op.tags, content="Some([\"pets\"])")
  // parameter name and location
  let param = list_op.parameters.unwrap()[0]
  guard param is @openapi.ParameterOrRef::ParameterValue(p) else {
    fail("expected ParameterValue")
  }
  inspect(p.name, content=(
    #|limit
  ))
  inspect(p.in_, content="Query")
  // 200 response
  let responses = list_op.responses.unwrap()
  inspect(responses.by_status.contains("200"), content="true")
  // components schemas
  let components = doc.components.unwrap()
  let schemas = components.schemas.unwrap()
  inspect(schemas.contains("Pet"), content="true")
  inspect(schemas.contains("NewPet"), content="true")
  // Pet schema required fields
  let pet_schema_or_ref = schemas["Pet"]
  guard pet_schema_or_ref is @openapi.SchemaOrRef::SchemaValue(pet_schema) else {
    fail("expected SchemaValue for Pet")
  }
  inspect(pet_schema.required, content="Some([\"id\", \"name\"])")
}

///|
test "parse error on invalid json" {
  let result = try? @openapi.parse("not json at all {{{")
  inspect(result is Err(_), content="true")
}

///|
test "parse error on wrong structure" {
  // Valid JSON but missing required 'info' field
  let minimal = #|{"openapi":"3.1.0"}
  let result = try? @openapi.parse(minimal)
  inspect(result is Err(_), content="true")
}

///|
test "security requirement round-trip" {
  let json =
    #|{
    #|  "openapi": "3.1.0",
    #|  "info": { "title": "Secure API", "version": "1.0.0" },
    #|  "security": [
    #|    { "bearerAuth": [] },
    #|    { "apiKey": ["read", "write"] }
    #|  ],
    #|  "components": {
    #|    "securitySchemes": {
    #|      "bearerAuth": {
    #|        "type": "http",
    #|        "scheme": "bearer",
    #|        "bearerFormat": "JWT"
    #|      }
    #|    }
    #|  }
    #|}
  let doc = @openapi.parse(json)
  let security = doc.security.unwrap()
  inspect(security.length(), content="2")
  let @openapi.SecurityRequirement(first_map) = security[0]
  inspect(first_map.contains("bearerAuth"), content="true")
}

///|
test "parse $ref in schema" {
  let json =
    #|{
    #|  "openapi": "3.1.0",
    #|  "info": { "title": "RefTest", "version": "0.1.0" },
    #|  "components": {
    #|    "schemas": {
    #|      "Widget": {
    #|        "$ref": "#/components/schemas/Base"
    #|      },
    #|      "Base": {
    #|        "type": "object",
    #|        "properties": {
    #|          "id": { "type": "integer" }
    #|        }
    #|      }
    #|    }
    #|  }
    #|}
  let doc = @openapi.parse(json)
  let schemas = doc.components.unwrap().schemas.unwrap()
  guard schemas["Widget"] is @openapi.SchemaOrRef::Ref(ref_obj) else {
    fail("expected Ref for Widget")
  }
  inspect(ref_obj.ref_, content=(
    #|#/components/schemas/Base
  ))
}
