// OpenAPI 3.1 data structures.
// All types are `pub(all)` so consumers can construct / inspect them directly.
// Field names mirror the JSON key names (snake_case aliases where needed).

///|
/// Top-level OpenAPI 3.1 document.
pub(all) struct OpenApiDocument {
  openapi : String
  info : Info
  json_schema_dialect : String?
  servers : Array[Server]?
  paths : Map[String, PathItem]
  webhooks : Map[String, PathItemOrRef]?
  components : Components?
  security : Array[SecurityRequirement]?
  tags : Array[Tag]?
  external_docs : ExternalDocs?
} derive(Show, Eq)

///|
pub(all) struct Info {
  title : String
  summary : String?
  description : String?
  terms_of_service : String?
  contact : Contact?
  license : License?
  version : String
} derive(Show, Eq)

///|
pub(all) struct Contact {
  name : String?
  url : String?
  email : String?
} derive(Show, Eq)

///|
pub(all) struct License {
  name : String
  identifier : String?
  url : String?
} derive(Show, Eq)

///|
pub(all) struct Server {
  url : String
  description : String?
  variables : Map[String, ServerVariable]?
} derive(Show, Eq)

///|
pub(all) struct ServerVariable {
  enum_ : Array[String]?
  default : String
  description : String?
} derive(Show, Eq)

///|
pub(all) struct PathItem {
  ref_ : String?
  summary : String?
  description : String?
  get : Operation?
  put : Operation?
  post : Operation?
  delete : Operation?
  options : Operation?
  head : Operation?
  patch : Operation?
  trace : Operation?
  servers : Array[Server]?
  parameters : Array[ParameterOrRef]?
} derive(Show, Eq)

///|
pub(all) enum PathItemOrRef {
  PathItemValue(PathItem)
  Ref(Reference)
} derive(Show, Eq)

///|
pub(all) struct Operation {
  tags : Array[String]?
  summary : String?
  description : String?
  external_docs : ExternalDocs?
  operation_id : String?
  parameters : Array[ParameterOrRef]?
  request_body : RequestBodyOrRef?
  responses : Responses
  callbacks : Map[String, CallbackOrRef]?
  deprecated : Bool?
  security : Array[SecurityRequirement]?
  servers : Array[Server]?
} derive(Show, Eq)

///|
pub(all) struct Parameter {
  name : String
  in_ : ParameterLocation
  description : String?
  required : Bool?
  deprecated : Bool?
  allow_empty_value : Bool?
  style : String?
  explode : Bool?
  allow_reserved : Bool?
  schema : SchemaOrRef?
  example : Json?
  examples : Map[String, ExampleOrRef]?
  content : Map[String, MediaType]?
} derive(Show, Eq)

///|
pub(all) enum ParameterLocation {
  Query
  Header
  Path
  Cookie
} derive(Show, Eq)

///|
pub(all) enum ParameterOrRef {
  ParameterValue(Parameter)
  Ref(Reference)
} derive(Show, Eq)

///|
pub(all) struct RequestBody {
  description : String?
  content : Map[String, MediaType]
  required : Bool?
} derive(Show, Eq)

///|
pub(all) enum RequestBodyOrRef {
  RequestBodyValue(RequestBody)
  Ref(Reference)
} derive(Show, Eq)

///|
pub(all) struct Responses {
  default : ResponseOrRef?
  by_status : Map[String, ResponseOrRef]
} derive(Show, Eq)

///|
pub(all) struct Response {
  description : String
  headers : Map[String, HeaderOrRef]?
  content : Map[String, MediaType]?
  links : Map[String, LinkOrRef]?
} derive(Show, Eq)

///|
pub(all) enum ResponseOrRef {
  ResponseValue(Response)
  Ref(Reference)
} derive(Show, Eq)

///|
pub(all) struct MediaType {
  schema : SchemaOrRef?
  example : Json?
  examples : Map[String, ExampleOrRef]?
  encoding : Map[String, Encoding]?
} derive(Show, Eq)

///|
pub(all) struct Encoding {
  content_type : String?
  headers : Map[String, HeaderOrRef]?
  style : String?
  explode : Bool?
  allow_reserved : Bool?
} derive(Show, Eq)

///|
pub(all) struct Header {
  description : String?
  required : Bool?
  deprecated : Bool?
  schema : SchemaOrRef?
  example : Json?
  examples : Map[String, ExampleOrRef]?
} derive(Show, Eq)

///|
pub(all) enum HeaderOrRef {
  HeaderValue(Header)
  Ref(Reference)
} derive(Show, Eq)

///|
pub(all) struct Example {
  summary : String?
  description : String?
  value : Json?
  external_value : String?
} derive(Show, Eq)

///|
pub(all) enum ExampleOrRef {
  ExampleValue(Example)
  Ref(Reference)
} derive(Show, Eq)

///|
pub(all) struct Link {
  operation_ref : String?
  operation_id : String?
  parameters : Map[String, Json]?
  request_body : Json?
  description : String?
  server : Server?
} derive(Show, Eq)

///|
pub(all) enum LinkOrRef {
  LinkValue(Link)
  Ref(Reference)
} derive(Show, Eq)

///|
/// Callbacks: map from runtime expression to PathItem (or $ref).
pub(all) enum CallbackOrRef {
  CallbackValue(Map[String, PathItemOrRef])
  Ref(Reference)
} derive(Show, Eq)

///|
pub(all) struct Tag {
  name : String
  description : String?
  external_docs : ExternalDocs?
} derive(Show, Eq)

///|
pub(all) struct ExternalDocs {
  description : String?
  url : String
} derive(Show, Eq)

///|
pub(all) struct Reference {
  ref_ : String
  summary : String?
  description : String?
} derive(Show, Eq)

///|
pub(all) enum SchemaOrRef {
  SchemaValue(Schema)
  Ref(Reference)
} derive(Show, Eq)

///|
pub(all) enum SchemaOrRefOrBool {
  SchemaOrRefValue(SchemaOrRef)
  BoolValue(Bool)
} derive(Show, Eq)

///|
/// JSON Schema (2020-12 compatible) / OpenAPI Schema Object.
pub(all) struct Schema {
  title : String?
  description : String?
  default : Json?
  examples : Array[Json]?
  type_ : SchemaType?
  format : String?
  enum_ : Array[Json]?
  const_ : Json?
  multiple_of : Double?
  maximum : Double?
  exclusive_maximum : Double?
  minimum : Double?
  exclusive_minimum : Double?
  max_length : Int?
  min_length : Int?
  pattern : String?
  items : SchemaOrRef?
  prefix_items : Array[SchemaOrRef]?
  max_items : Int?
  min_items : Int?
  unique_items : Bool?
  contains : SchemaOrRef?
  max_contains : Int?
  min_contains : Int?
  properties : Map[String, SchemaOrRef]?
  pattern_properties : Map[String, SchemaOrRef]?
  additional_properties : SchemaOrRefOrBool?
  unevaluated_properties : SchemaOrRefOrBool?
  required : Array[String]?
  property_names : SchemaOrRef?
  max_properties : Int?
  min_properties : Int?
  dependent_required : Map[String, Array[String]]?
  dependent_schemas : Map[String, SchemaOrRef]?
  all_of : Array[SchemaOrRef]?
  any_of : Array[SchemaOrRef]?
  one_of : Array[SchemaOrRef]?
  not : SchemaOrRef?
  if_ : SchemaOrRef?
  then_ : SchemaOrRef?
  else_ : SchemaOrRef?
  discriminator : Discriminator?
  xml : Xml?
  external_docs : ExternalDocs?
  example : Json?
  deprecated : Bool?
  read_only : Bool?
  write_only : Bool?
  nullable : Bool?
} derive(Show, Eq)

///|
pub(all) enum SchemaType {
  Single(String)
  Multiple(Array[String])
} derive(Show, Eq)

///|
pub(all) struct Discriminator {
  property_name : String
  mapping : Map[String, String]?
} derive(Show, Eq)

///|
pub(all) struct Xml {
  name : String?
  xml_namespace : String?
  prefix : String?
  attribute : Bool?
  wrapped : Bool?
} derive(Show, Eq)

///|
pub(all) struct Components {
  schemas : Map[String, SchemaOrRef]?
  responses : Map[String, ResponseOrRef]?
  parameters : Map[String, ParameterOrRef]?
  examples : Map[String, ExampleOrRef]?
  request_bodies : Map[String, RequestBodyOrRef]?
  headers : Map[String, HeaderOrRef]?
  security_schemes : Map[String, SecuritySchemeOrRef]?
  links : Map[String, LinkOrRef]?
  callbacks : Map[String, CallbackOrRef]?
  path_items : Map[String, PathItemOrRef]?
} derive(Show, Eq)

///|
pub(all) struct SecurityScheme {
  type_ : String
  description : String?
  name : String?
  in_ : String?
  scheme : String?
  bearer_format : String?
  flows : OAuthFlows?
  open_id_connect_url : String?
} derive(Show, Eq)

///|
pub(all) enum SecuritySchemeOrRef {
  SecuritySchemeValue(SecurityScheme)
  Ref(Reference)
} derive(Show, Eq)

///|
pub(all) struct OAuthFlows {
  implicit : OAuthFlow?
  password : OAuthFlow?
  client_credentials : OAuthFlow?
  authorization_code : OAuthFlow?
} derive(Show, Eq)

///|
pub(all) struct OAuthFlow {
  authorization_url : String?
  token_url : String?
  refresh_url : String?
  scopes : Map[String, String]
} derive(Show, Eq)

///|
/// SecurityRequirement: map from scheme name to list of scopes.
pub(all) struct SecurityRequirement(Map[String, Array[String]]) derive(Show, Eq)
