// SARIF 2.1.0 data structures.
// Field names mirror SARIF JSON keys (snake_case aliases where needed).

///|
pub(all) struct SarifLog {
  version : String
  schema : String?
  runs : Array[Run]
} derive(Show, Eq)

///|
pub(all) struct Run {
  tool : Tool
  invocations : Array[Invocation]?
  artifacts : Array[Artifact]?
  logical_locations : Array[LogicalLocation]?
  results : Array[Result]?
  version_control_provenance : Array[VersionControlDetails]?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct Tool {
  driver : ToolComponent
  extensions : Array[ToolComponent]?
} derive(Show, Eq)

///|
pub(all) struct ToolComponent {
  name : String
  information_uri : String?
  full_name : String?
  version : String?
  semantic_version : String?
  rules : Array[ReportingDescriptor]?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct ReportingDescriptor {
  id : String
  name : String?
  short_description : MultiformatMessageString?
  full_description : MultiformatMessageString?
  help_uri : String?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct Result {
  rule_id : String?
  rule_index : Int?
  kind : String?
  level : ResultLevel?
  message : Message
  locations : Array[Location]?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) enum ResultLevel {
  None_
  Note
  Warning
  Error
} derive(Show, Eq)

///|
pub(all) struct Message {
  text : String?
  markdown : String?
  id : String?
  arguments : Array[String]?
} derive(Show, Eq)

///|
pub(all) struct Location {
  id : Int?
  physical_location : PhysicalLocation?
  logical_locations : Array[LogicalLocation]?
  message : Message?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct PhysicalLocation {
  artifact_location : ArtifactLocation?
  region : Region?
  context_region : Region?
} derive(Show, Eq)

///|
pub(all) struct ArtifactLocation {
  uri : String?
  uri_base_id : String?
  index : Int?
  description : Message?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct Region {
  start_line : Int?
  start_column : Int?
  end_line : Int?
  end_column : Int?
  snippet : ArtifactContent?
  message : Message?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct LogicalLocation {
  name : String?
  index : Int?
  fully_qualified_name : String?
  decorated_name : String?
  kind : String?
  parent_index : Int?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct Artifact {
  location : ArtifactLocation?
  parent_index : Int?
  offset : Int?
  length : Int?
  mime_type : String?
  encoding : String?
  source_language : String?
  contents : ArtifactContent?
  description : Message?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct ArtifactContent {
  text : String?
  binary : String?
  rendered : MultiformatMessageString?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct Invocation {
  command_line : String?
  arguments : Array[String]?
  working_directory : ArtifactLocation?
  end_time_utc : String?
  exit_code : Int?
  execution_successful : Bool?
  process_id : Int?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct VersionControlDetails {
  repository_uri : String?
  revision_id : String?
  branch : String?
  as_of_time_utc : String?
  mapped_to : ArtifactLocation?
  properties : Map[String, Json]?
} derive(Show, Eq)

///|
pub(all) struct MultiformatMessageString {
  text : String?
  markdown : String?
} derive(Show, Eq)
