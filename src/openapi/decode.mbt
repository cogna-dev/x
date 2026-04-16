// FromJson implementations for all OpenAPI 3.1 types.
// Entry point: `parse(json_string) -> OpenApiDocument raise ParseOpenApiError`

///|
pub suberror ParseOpenApiError {
  JsonParse(@json.ParseError)
  JsonDecode(@json.JsonDecodeError)
} derive(Show)

///|
/// Parse an OpenAPI 3.1 JSON string into an `OpenApiDocument`.
pub fn parse(s : String) -> OpenApiDocument raise ParseOpenApiError {
  let json = try {
    @json.parse(s)
  } catch {
    e => raise ParseOpenApiError::JsonParse(e)
  }
  try {
    @json.from_json(json)
  } catch {
    e => raise ParseOpenApiError::JsonDecode(e)
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn[T : @json.FromJson] get_opt(
  obj : Map[String, Json],
  key : String,
  path : @json.JsonPath
) -> T? raise @json.JsonDecodeError {
  match obj.get(key) {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key(key)))
  }
}

fn[T : @json.FromJson] get_req(
  obj : Map[String, Json],
  key : String,
  path : @json.JsonPath
) -> T raise @json.JsonDecodeError {
  match obj.get(key) {
    None | Some(Null) =>
      raise @json.JsonDecodeError((path.add_key(key), "required field missing"))
    Some(v) => @json.from_json(v, path=path.add_key(key))
  }
}

// ---------------------------------------------------------------------------
// OpenApiDocument
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for OpenApiDocument with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "OpenApiDocument: expected object"))
  }
  {
    openapi: get_req(obj, "openapi", path),
    info: get_req(obj, "info", path),
    json_schema_dialect: get_opt(obj, "jsonSchemaDialect", path),
    servers: get_opt(obj, "servers", path),
    paths: get_opt(obj, "paths", path),
    webhooks: get_opt(obj, "webhooks", path),
    components: get_opt(obj, "components", path),
    security: get_opt(obj, "security", path),
    tags: get_opt(obj, "tags", path),
    external_docs: get_opt(obj, "externalDocs", path),
  }
}

// ---------------------------------------------------------------------------
// Info
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Info with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Info: expected object"))
  }
  {
    title: get_req(obj, "title", path),
    summary: get_opt(obj, "summary", path),
    description: get_opt(obj, "description", path),
    terms_of_service: get_opt(obj, "termsOfService", path),
    contact: get_opt(obj, "contact", path),
    license: get_opt(obj, "license", path),
    version: get_req(obj, "version", path),
  }
}

// ---------------------------------------------------------------------------
// Contact
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Contact with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Contact: expected object"))
  }
  {
    name: get_opt(obj, "name", path),
    url: get_opt(obj, "url", path),
    email: get_opt(obj, "email", path),
  }
}

// ---------------------------------------------------------------------------
// License
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for License with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "License: expected object"))
  }
  {
    name: get_req(obj, "name", path),
    identifier: get_opt(obj, "identifier", path),
    url: get_opt(obj, "url", path),
  }
}

// ---------------------------------------------------------------------------
// Server / ServerVariable
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Server with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Server: expected object"))
  }
  {
    url: get_req(obj, "url", path),
    description: get_opt(obj, "description", path),
    variables: get_opt(obj, "variables", path),
  }
}

///|
impl @json.FromJson for ServerVariable with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ServerVariable: expected object"))
  }
  {
    enum_: get_opt(obj, "enum", path),
    default: get_req(obj, "default", path),
    description: get_opt(obj, "description", path),
  }
}

// ---------------------------------------------------------------------------
// Reference
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Reference with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Reference: expected object"))
  }
  {
    ref_: get_req(obj, "$ref", path),
    summary: get_opt(obj, "summary", path),
    description: get_opt(obj, "description", path),
  }
}

// ---------------------------------------------------------------------------
// PathItem / PathItemOrRef
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for PathItem with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "PathItem: expected object"))
  }
  {
    ref_: get_opt(obj, "$ref", path),
    summary: get_opt(obj, "summary", path),
    description: get_opt(obj, "description", path),
    get: get_opt(obj, "get", path),
    put: get_opt(obj, "put", path),
    post: get_opt(obj, "post", path),
    delete: get_opt(obj, "delete", path),
    options: get_opt(obj, "options", path),
    head: get_opt(obj, "head", path),
    patch: get_opt(obj, "patch", path),
    trace: get_opt(obj, "trace", path),
    servers: get_opt(obj, "servers", path),
    parameters: get_opt(obj, "parameters", path),
  }
}

///|
impl @json.FromJson for PathItemOrRef with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "PathItemOrRef: expected object"))
  }
  if obj.contains("$ref") {
    Ref(@json.from_json(json, path~))
  } else {
    PathItemValue(@json.from_json(json, path~))
  }
}

// ---------------------------------------------------------------------------
// Operation
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Operation with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Operation: expected object"))
  }
  {
    tags: get_opt(obj, "tags", path),
    summary: get_opt(obj, "summary", path),
    description: get_opt(obj, "description", path),
    external_docs: get_opt(obj, "externalDocs", path),
    operation_id: get_opt(obj, "operationId", path),
    parameters: get_opt(obj, "parameters", path),
    request_body: get_opt(obj, "requestBody", path),
    responses: get_opt(obj, "responses", path),
    callbacks: get_opt(obj, "callbacks", path),
    deprecated: get_opt(obj, "deprecated", path),
    security: get_opt(obj, "security", path),
    servers: get_opt(obj, "servers", path),
  }
}

// ---------------------------------------------------------------------------
// Parameter / ParameterLocation / ParameterOrRef
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for ParameterLocation with from_json(json, path) {
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "ParameterLocation: expected string"))
  }
  match s {
    "query" => Query
    "header" => Header
    "path" => Path
    "cookie" => Cookie
    _ =>
      raise @json.JsonDecodeError(
        (path, "ParameterLocation: unknown value '\{s}'"),
      )
  }
}

///|
impl @json.FromJson for Parameter with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Parameter: expected object"))
  }
  {
    name: get_req(obj, "name", path),
    in_: get_req(obj, "in", path),
    description: get_opt(obj, "description", path),
    required: get_opt(obj, "required", path),
    deprecated: get_opt(obj, "deprecated", path),
    allow_empty_value: get_opt(obj, "allowEmptyValue", path),
    style: get_opt(obj, "style", path),
    explode: get_opt(obj, "explode", path),
    allow_reserved: get_opt(obj, "allowReserved", path),
    schema: get_opt(obj, "schema", path),
    example: get_opt(obj, "example", path),
    examples: get_opt(obj, "examples", path),
    content: get_opt(obj, "content", path),
  }
}

///|
impl @json.FromJson for ParameterOrRef with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ParameterOrRef: expected object"))
  }
  if obj.contains("$ref") {
    Ref(@json.from_json(json, path~))
  } else {
    ParameterValue(@json.from_json(json, path~))
  }
}

// ---------------------------------------------------------------------------
// RequestBody / RequestBodyOrRef
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for RequestBody with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "RequestBody: expected object"))
  }
  {
    description: get_opt(obj, "description", path),
    content: get_req(obj, "content", path),
    required: get_opt(obj, "required", path),
  }
}

///|
impl @json.FromJson for RequestBodyOrRef with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "RequestBodyOrRef: expected object"))
  }
  if obj.contains("$ref") {
    Ref(@json.from_json(json, path~))
  } else {
    RequestBodyValue(@json.from_json(json, path~))
  }
}

// ---------------------------------------------------------------------------
// Responses / Response / ResponseOrRef
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Responses with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Responses: expected object"))
  }
  let default_val : ResponseOrRef? = get_opt(obj, "default", path)
  let by_status : Map[String, ResponseOrRef] = {}
  for k, v in obj {
    if k == "default" {
      continue
    }
    by_status[k] = @json.from_json(v, path=path.add_key(k))
  }
  { default: default_val, by_status }
}

///|
impl @json.FromJson for Response with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Response: expected object"))
  }
  {
    description: get_req(obj, "description", path),
    headers: get_opt(obj, "headers", path),
    content: get_opt(obj, "content", path),
    links: get_opt(obj, "links", path),
  }
}

///|
impl @json.FromJson for ResponseOrRef with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ResponseOrRef: expected object"))
  }
  if obj.contains("$ref") {
    Ref(@json.from_json(json, path~))
  } else {
    ResponseValue(@json.from_json(json, path~))
  }
}

// ---------------------------------------------------------------------------
// MediaType / Encoding
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for MediaType with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "MediaType: expected object"))
  }
  {
    schema: get_opt(obj, "schema", path),
    example: get_opt(obj, "example", path),
    examples: get_opt(obj, "examples", path),
    encoding: get_opt(obj, "encoding", path),
  }
}

///|
impl @json.FromJson for Encoding with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Encoding: expected object"))
  }
  {
    content_type: get_opt(obj, "contentType", path),
    headers: get_opt(obj, "headers", path),
    style: get_opt(obj, "style", path),
    explode: get_opt(obj, "explode", path),
    allow_reserved: get_opt(obj, "allowReserved", path),
  }
}

// ---------------------------------------------------------------------------
// Header / HeaderOrRef
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Header with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Header: expected object"))
  }
  {
    description: get_opt(obj, "description", path),
    required: get_opt(obj, "required", path),
    deprecated: get_opt(obj, "deprecated", path),
    schema: get_opt(obj, "schema", path),
    example: get_opt(obj, "example", path),
    examples: get_opt(obj, "examples", path),
  }
}

///|
impl @json.FromJson for HeaderOrRef with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "HeaderOrRef: expected object"))
  }
  if obj.contains("$ref") {
    Ref(@json.from_json(json, path~))
  } else {
    HeaderValue(@json.from_json(json, path~))
  }
}

// ---------------------------------------------------------------------------
// Example / ExampleOrRef
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Example with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Example: expected object"))
  }
  {
    summary: get_opt(obj, "summary", path),
    description: get_opt(obj, "description", path),
    value: get_opt(obj, "value", path),
    external_value: get_opt(obj, "externalValue", path),
  }
}

///|
impl @json.FromJson for ExampleOrRef with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ExampleOrRef: expected object"))
  }
  if obj.contains("$ref") {
    Ref(@json.from_json(json, path~))
  } else {
    ExampleValue(@json.from_json(json, path~))
  }
}

// ---------------------------------------------------------------------------
// Link / LinkOrRef
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Link with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Link: expected object"))
  }
  {
    operation_ref: get_opt(obj, "operationRef", path),
    operation_id: get_opt(obj, "operationId", path),
    parameters: get_opt(obj, "parameters", path),
    request_body: get_opt(obj, "requestBody", path),
    description: get_opt(obj, "description", path),
    server: get_opt(obj, "server", path),
  }
}

///|
impl @json.FromJson for LinkOrRef with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "LinkOrRef: expected object"))
  }
  if obj.contains("$ref") {
    Ref(@json.from_json(json, path~))
  } else {
    LinkValue(@json.from_json(json, path~))
  }
}

// ---------------------------------------------------------------------------
// CallbackOrRef
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for CallbackOrRef with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "CallbackOrRef: expected object"))
  }
  if obj.contains("$ref") {
    Ref(@json.from_json(json, path~))
  } else {
    let m : Map[String, PathItemOrRef] = {}
    for k, v in obj {
      m[k] = @json.from_json(v, path=path.add_key(k))
    }
    CallbackValue(m)
  }
}

// ---------------------------------------------------------------------------
// Tag / ExternalDocs
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Tag with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Tag: expected object"))
  }
  {
    name: get_req(obj, "name", path),
    description: get_opt(obj, "description", path),
    external_docs: get_opt(obj, "externalDocs", path),
  }
}

///|
impl @json.FromJson for ExternalDocs with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ExternalDocs: expected object"))
  }
  {
    description: get_opt(obj, "description", path),
    url: get_req(obj, "url", path),
  }
}

// ---------------------------------------------------------------------------
// Schema / SchemaOrRef / SchemaOrRefOrBool / SchemaType
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for SchemaType with from_json(json, path) {
  match json {
    String(s) => Single(s)
    Array(arr) => {
      let strs : Array[String] = []
      for item in arr {
        guard item is String(s) else {
          raise @json.JsonDecodeError(
            (path, "SchemaType array: expected strings"),
          )
        }
        strs.push(s)
      }
      Multiple(strs)
    }
    _ =>
      raise @json.JsonDecodeError(
        (path, "SchemaType: expected string or array"),
      )
  }
}

///|
impl @json.FromJson for SchemaOrRef with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "SchemaOrRef: expected object"))
  }
  if obj.contains("$ref") {
    Ref(@json.from_json(json, path~))
  } else {
    SchemaValue(@json.from_json(json, path~))
  }
}

///|
impl @json.FromJson for SchemaOrRefOrBool with from_json(json, path) {
  match json {
    True => BoolValue(true)
    False => BoolValue(false)
    Object(_) => SchemaOrRefValue(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path, "SchemaOrRefOrBool: expected object or bool"),
      )
  }
}

///|
impl @json.FromJson for Schema with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Schema: expected object"))
  }
  {
    title: get_opt(obj, "title", path),
    description: get_opt(obj, "description", path),
    default: get_opt(obj, "default", path),
    examples: get_opt(obj, "examples", path),
    type_: get_opt(obj, "type", path),
    format: get_opt(obj, "format", path),
    enum_: get_opt(obj, "enum", path),
    const_: get_opt(obj, "const", path),
    multiple_of: get_opt(obj, "multipleOf", path),
    maximum: get_opt(obj, "maximum", path),
    exclusive_maximum: get_opt(obj, "exclusiveMaximum", path),
    minimum: get_opt(obj, "minimum", path),
    exclusive_minimum: get_opt(obj, "exclusiveMinimum", path),
    max_length: get_opt(obj, "maxLength", path),
    min_length: get_opt(obj, "minLength", path),
    pattern: get_opt(obj, "pattern", path),
    items: get_opt(obj, "items", path),
    prefix_items: get_opt(obj, "prefixItems", path),
    max_items: get_opt(obj, "maxItems", path),
    min_items: get_opt(obj, "minItems", path),
    unique_items: get_opt(obj, "uniqueItems", path),
    contains: get_opt(obj, "contains", path),
    max_contains: get_opt(obj, "maxContains", path),
    min_contains: get_opt(obj, "minContains", path),
    properties: get_opt(obj, "properties", path),
    pattern_properties: get_opt(obj, "patternProperties", path),
    additional_properties: get_opt(obj, "additionalProperties", path),
    unevaluated_properties: get_opt(obj, "unevaluatedProperties", path),
    required: get_opt(obj, "required", path),
    property_names: get_opt(obj, "propertyNames", path),
    max_properties: get_opt(obj, "maxProperties", path),
    min_properties: get_opt(obj, "minProperties", path),
    dependent_required: get_opt(obj, "dependentRequired", path),
    dependent_schemas: get_opt(obj, "dependentSchemas", path),
    all_of: get_opt(obj, "allOf", path),
    any_of: get_opt(obj, "anyOf", path),
    one_of: get_opt(obj, "oneOf", path),
    not: get_opt(obj, "not", path),
    if_: get_opt(obj, "if", path),
    then_: get_opt(obj, "then", path),
    else_: get_opt(obj, "else", path),
    discriminator: get_opt(obj, "discriminator", path),
    xml: get_opt(obj, "xml", path),
    external_docs: get_opt(obj, "externalDocs", path),
    example: get_opt(obj, "example", path),
    deprecated: get_opt(obj, "deprecated", path),
    read_only: get_opt(obj, "readOnly", path),
    write_only: get_opt(obj, "writeOnly", path),
    nullable: get_opt(obj, "nullable", path),
  }
}

// ---------------------------------------------------------------------------
// Discriminator / Xml
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Discriminator with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Discriminator: expected object"))
  }
  {
    property_name: get_req(obj, "propertyName", path),
    mapping: get_opt(obj, "mapping", path),
  }
}

///|
impl @json.FromJson for Xml with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Xml: expected object"))
  }
  {
    name: get_opt(obj, "name", path),
    xml_namespace: get_opt(obj, "namespace", path),
    prefix: get_opt(obj, "prefix", path),
    attribute: get_opt(obj, "attribute", path),
    wrapped: get_opt(obj, "wrapped", path),
  }
}

// ---------------------------------------------------------------------------
// Components
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for Components with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Components: expected object"))
  }
  {
    schemas: get_opt(obj, "schemas", path),
    responses: get_opt(obj, "responses", path),
    parameters: get_opt(obj, "parameters", path),
    examples: get_opt(obj, "examples", path),
    request_bodies: get_opt(obj, "requestBodies", path),
    headers: get_opt(obj, "headers", path),
    security_schemes: get_opt(obj, "securitySchemes", path),
    links: get_opt(obj, "links", path),
    callbacks: get_opt(obj, "callbacks", path),
    path_items: get_opt(obj, "pathItems", path),
  }
}

// ---------------------------------------------------------------------------
// SecurityScheme / SecuritySchemeOrRef / OAuthFlows / OAuthFlow
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for SecurityScheme with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "SecurityScheme: expected object"))
  }
  {
    type_: get_req(obj, "type", path),
    description: get_opt(obj, "description", path),
    name: get_opt(obj, "name", path),
    in_: get_opt(obj, "in", path),
    scheme: get_opt(obj, "scheme", path),
    bearer_format: get_opt(obj, "bearerFormat", path),
    flows: get_opt(obj, "flows", path),
    open_id_connect_url: get_opt(obj, "openIdConnectUrl", path),
  }
}

///|
impl @json.FromJson for SecuritySchemeOrRef with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "SecuritySchemeOrRef: expected object"))
  }
  if obj.contains("$ref") {
    Ref(@json.from_json(json, path~))
  } else {
    SecuritySchemeValue(@json.from_json(json, path~))
  }
}

///|
impl @json.FromJson for OAuthFlows with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "OAuthFlows: expected object"))
  }
  {
    implicit: get_opt(obj, "implicit", path),
    password: get_opt(obj, "password", path),
    client_credentials: get_opt(obj, "clientCredentials", path),
    authorization_code: get_opt(obj, "authorizationCode", path),
  }
}

///|
impl @json.FromJson for OAuthFlow with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "OAuthFlow: expected object"))
  }
  {
    authorization_url: get_opt(obj, "authorizationUrl", path),
    token_url: get_opt(obj, "tokenUrl", path),
    refresh_url: get_opt(obj, "refreshUrl", path),
    scopes: get_req(obj, "scopes", path),
  }
}

// ---------------------------------------------------------------------------
// SecurityRequirement
// ---------------------------------------------------------------------------

///|
impl @json.FromJson for SecurityRequirement with from_json(json, path) {
  let m : Map[String, Array[String]] = @json.from_json(json, path~)
  SecurityRequirement(m)
}
