// JSON encode/decode for SARIF 2.1.0 structures.
// Entry points:
// - parse(json_string) -> SarifLog
// - stringify(log) -> JSON string

///|
pub suberror ParseSarifError {
  JsonParse(@json.ParseError)
  JsonDecode(@json.JsonDecodeError)
} derive(Show)

///|
pub fn parse(s : String) -> SarifLog raise ParseSarifError {
  let json = @json.parse(s) catch { e => raise ParseSarifError::JsonParse(e) }
  @json.from_json(json) catch {
    e => raise ParseSarifError::JsonDecode(e)
  }
}

///|
pub fn stringify(log : SarifLog, indent? : Int) -> String {
  match indent {
    Some(i) => log.to_json().stringify(indent=i)
    None => log.to_json().stringify()
  }
}

///|
fn[T : @json.FromJson] get_opt(
  obj : Map[String, Json],
  key : String,
  path : @json.JsonPath,
) -> T? raise @json.JsonDecodeError {
  match obj.get(key) {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key(key)))
  }
}

///|
fn[T : @json.FromJson] get_req(
  obj : Map[String, Json],
  key : String,
  path : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  match obj.get(key) {
    None | Some(Null) =>
      raise @json.JsonDecodeError((path.add_key(key), "required field missing"))
    Some(v) => @json.from_json(v, path=path.add_key(key))
  }
}

///|
fn[T : ToJson] put_opt(obj : Map[String, Json], key : String, value : T?) -> Unit {
  if value is Some(v) {
    obj[key] = v.to_json()
  }
}

///|
fn level_to_string(level : ResultLevel) -> String {
  match level {
    None_ => "none"
    Note => "note"
    Warning => "warning"
    Error => "error"
  }
}

///|
impl ToJson for ResultLevel with to_json(self) {
  Json::string(level_to_string(self))
}

///|
impl @json.FromJson for ResultLevel with from_json(json, path) {
  match json {
    String("none") => None_
    String("note") => Note
    String("warning") => Warning
    String("error") => Error
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResultLevel: expected one of none, note, warning, error"),
      )
  }
}

///|
impl ToJson for SarifLog with to_json(self) {
  let obj : Map[String, Json] = {
    "version": self.version.to_json(),
    "runs": self.runs.to_json(),
  }
  put_opt(obj, "$schema", self.schema)
  Json::object(obj)
}

///|
impl @json.FromJson for SarifLog with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "SarifLog: expected object"))
  }
  {
    version: get_req(obj, "version", path),
    schema: get_opt(obj, "$schema", path),
    runs: get_req(obj, "runs", path),
  }
}

///|
impl ToJson for Run with to_json(self) {
  let obj : Map[String, Json] = { "tool": self.tool.to_json() }
  put_opt(obj, "invocations", self.invocations)
  put_opt(obj, "artifacts", self.artifacts)
  put_opt(obj, "logicalLocations", self.logical_locations)
  put_opt(obj, "results", self.results)
  put_opt(obj, "versionControlProvenance", self.version_control_provenance)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for Run with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Run: expected object"))
  }
  {
    tool: get_req(obj, "tool", path),
    invocations: get_opt(obj, "invocations", path),
    artifacts: get_opt(obj, "artifacts", path),
    logical_locations: get_opt(obj, "logicalLocations", path),
    results: get_opt(obj, "results", path),
    version_control_provenance: get_opt(obj, "versionControlProvenance", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for Tool with to_json(self) {
  let obj : Map[String, Json] = { "driver": self.driver.to_json() }
  put_opt(obj, "extensions", self.extensions)
  Json::object(obj)
}

///|
impl @json.FromJson for Tool with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Tool: expected object"))
  }
  {
    driver: get_req(obj, "driver", path),
    extensions: get_opt(obj, "extensions", path),
  }
}

///|
impl ToJson for ToolComponent with to_json(self) {
  let obj : Map[String, Json] = { "name": self.name.to_json() }
  put_opt(obj, "informationUri", self.information_uri)
  put_opt(obj, "fullName", self.full_name)
  put_opt(obj, "version", self.version)
  put_opt(obj, "semanticVersion", self.semantic_version)
  put_opt(obj, "rules", self.rules)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for ToolComponent with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ToolComponent: expected object"))
  }
  {
    name: get_req(obj, "name", path),
    information_uri: get_opt(obj, "informationUri", path),
    full_name: get_opt(obj, "fullName", path),
    version: get_opt(obj, "version", path),
    semantic_version: get_opt(obj, "semanticVersion", path),
    rules: get_opt(obj, "rules", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for ReportingDescriptor with to_json(self) {
  let obj : Map[String, Json] = { "id": self.id.to_json() }
  put_opt(obj, "name", self.name)
  put_opt(obj, "shortDescription", self.short_description)
  put_opt(obj, "fullDescription", self.full_description)
  put_opt(obj, "helpUri", self.help_uri)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for ReportingDescriptor with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ReportingDescriptor: expected object"))
  }
  {
    id: get_req(obj, "id", path),
    name: get_opt(obj, "name", path),
    short_description: get_opt(obj, "shortDescription", path),
    full_description: get_opt(obj, "fullDescription", path),
    help_uri: get_opt(obj, "helpUri", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for Result with to_json(self) {
  let obj : Map[String, Json] = { "message": self.message.to_json() }
  put_opt(obj, "ruleId", self.rule_id)
  put_opt(obj, "ruleIndex", self.rule_index)
  put_opt(obj, "kind", self.kind)
  put_opt(obj, "level", self.level)
  put_opt(obj, "locations", self.locations)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for Result with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Result: expected object"))
  }
  {
    rule_id: get_opt(obj, "ruleId", path),
    rule_index: get_opt(obj, "ruleIndex", path),
    kind: get_opt(obj, "kind", path),
    level: get_opt(obj, "level", path),
    message: get_req(obj, "message", path),
    locations: get_opt(obj, "locations", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for Message with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "text", self.text)
  put_opt(obj, "markdown", self.markdown)
  put_opt(obj, "id", self.id)
  put_opt(obj, "arguments", self.arguments)
  Json::object(obj)
}

///|
impl @json.FromJson for Message with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Message: expected object"))
  }
  {
    text: get_opt(obj, "text", path),
    markdown: get_opt(obj, "markdown", path),
    id: get_opt(obj, "id", path),
    arguments: get_opt(obj, "arguments", path),
  }
}

///|
impl ToJson for Location with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "id", self.id)
  put_opt(obj, "physicalLocation", self.physical_location)
  put_opt(obj, "logicalLocations", self.logical_locations)
  put_opt(obj, "message", self.message)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for Location with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Location: expected object"))
  }
  {
    id: get_opt(obj, "id", path),
    physical_location: get_opt(obj, "physicalLocation", path),
    logical_locations: get_opt(obj, "logicalLocations", path),
    message: get_opt(obj, "message", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for PhysicalLocation with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "artifactLocation", self.artifact_location)
  put_opt(obj, "region", self.region)
  put_opt(obj, "contextRegion", self.context_region)
  Json::object(obj)
}

///|
impl @json.FromJson for PhysicalLocation with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "PhysicalLocation: expected object"))
  }
  {
    artifact_location: get_opt(obj, "artifactLocation", path),
    region: get_opt(obj, "region", path),
    context_region: get_opt(obj, "contextRegion", path),
  }
}

///|
impl ToJson for ArtifactLocation with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "uri", self.uri)
  put_opt(obj, "uriBaseId", self.uri_base_id)
  put_opt(obj, "index", self.index)
  put_opt(obj, "description", self.description)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for ArtifactLocation with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ArtifactLocation: expected object"))
  }
  {
    uri: get_opt(obj, "uri", path),
    uri_base_id: get_opt(obj, "uriBaseId", path),
    index: get_opt(obj, "index", path),
    description: get_opt(obj, "description", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for Region with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "startLine", self.start_line)
  put_opt(obj, "startColumn", self.start_column)
  put_opt(obj, "endLine", self.end_line)
  put_opt(obj, "endColumn", self.end_column)
  put_opt(obj, "snippet", self.snippet)
  put_opt(obj, "message", self.message)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for Region with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Region: expected object"))
  }
  {
    start_line: get_opt(obj, "startLine", path),
    start_column: get_opt(obj, "startColumn", path),
    end_line: get_opt(obj, "endLine", path),
    end_column: get_opt(obj, "endColumn", path),
    snippet: get_opt(obj, "snippet", path),
    message: get_opt(obj, "message", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for LogicalLocation with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "name", self.name)
  put_opt(obj, "index", self.index)
  put_opt(obj, "fullyQualifiedName", self.fully_qualified_name)
  put_opt(obj, "decoratedName", self.decorated_name)
  put_opt(obj, "kind", self.kind)
  put_opt(obj, "parentIndex", self.parent_index)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for LogicalLocation with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "LogicalLocation: expected object"))
  }
  {
    name: get_opt(obj, "name", path),
    index: get_opt(obj, "index", path),
    fully_qualified_name: get_opt(obj, "fullyQualifiedName", path),
    decorated_name: get_opt(obj, "decoratedName", path),
    kind: get_opt(obj, "kind", path),
    parent_index: get_opt(obj, "parentIndex", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for Artifact with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "location", self.location)
  put_opt(obj, "parentIndex", self.parent_index)
  put_opt(obj, "offset", self.offset)
  put_opt(obj, "length", self.length)
  put_opt(obj, "mimeType", self.mime_type)
  put_opt(obj, "encoding", self.encoding)
  put_opt(obj, "sourceLanguage", self.source_language)
  put_opt(obj, "contents", self.contents)
  put_opt(obj, "description", self.description)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for Artifact with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Artifact: expected object"))
  }
  {
    location: get_opt(obj, "location", path),
    parent_index: get_opt(obj, "parentIndex", path),
    offset: get_opt(obj, "offset", path),
    length: get_opt(obj, "length", path),
    mime_type: get_opt(obj, "mimeType", path),
    encoding: get_opt(obj, "encoding", path),
    source_language: get_opt(obj, "sourceLanguage", path),
    contents: get_opt(obj, "contents", path),
    description: get_opt(obj, "description", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for ArtifactContent with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "text", self.text)
  put_opt(obj, "binary", self.binary)
  put_opt(obj, "rendered", self.rendered)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for ArtifactContent with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ArtifactContent: expected object"))
  }
  {
    text: get_opt(obj, "text", path),
    binary: get_opt(obj, "binary", path),
    rendered: get_opt(obj, "rendered", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for Invocation with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "commandLine", self.command_line)
  put_opt(obj, "arguments", self.arguments)
  put_opt(obj, "workingDirectory", self.working_directory)
  put_opt(obj, "endTimeUtc", self.end_time_utc)
  put_opt(obj, "exitCode", self.exit_code)
  put_opt(obj, "executionSuccessful", self.execution_successful)
  put_opt(obj, "processId", self.process_id)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for Invocation with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "Invocation: expected object"))
  }
  {
    command_line: get_opt(obj, "commandLine", path),
    arguments: get_opt(obj, "arguments", path),
    working_directory: get_opt(obj, "workingDirectory", path),
    end_time_utc: get_opt(obj, "endTimeUtc", path),
    exit_code: get_opt(obj, "exitCode", path),
    execution_successful: get_opt(obj, "executionSuccessful", path),
    process_id: get_opt(obj, "processId", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for VersionControlDetails with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "repositoryUri", self.repository_uri)
  put_opt(obj, "revisionId", self.revision_id)
  put_opt(obj, "branch", self.branch)
  put_opt(obj, "asOfTimeUtc", self.as_of_time_utc)
  put_opt(obj, "mappedTo", self.mapped_to)
  put_opt(obj, "properties", self.properties)
  Json::object(obj)
}

///|
impl @json.FromJson for VersionControlDetails with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "VersionControlDetails: expected object"))
  }
  {
    repository_uri: get_opt(obj, "repositoryUri", path),
    revision_id: get_opt(obj, "revisionId", path),
    branch: get_opt(obj, "branch", path),
    as_of_time_utc: get_opt(obj, "asOfTimeUtc", path),
    mapped_to: get_opt(obj, "mappedTo", path),
    properties: get_opt(obj, "properties", path),
  }
}

///|
impl ToJson for MultiformatMessageString with to_json(self) {
  let obj : Map[String, Json] = {}
  put_opt(obj, "text", self.text)
  put_opt(obj, "markdown", self.markdown)
  Json::object(obj)
}

///|
impl @json.FromJson for MultiformatMessageString with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "MultiformatMessageString: expected object"))
  }
  {
    text: get_opt(obj, "text", path),
    markdown: get_opt(obj, "markdown", path),
  }
}
