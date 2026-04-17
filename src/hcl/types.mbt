///|
/// 1-based source position in the parsed HCL input (`line`, `col`).
pub(all) struct Position {
  /// 1-based line index.
  line : Int
  /// 1-based column index.
  col : Int
} derive(Show, Eq)

///|
/// Parsed HCL document.
pub(all) struct Document {
  body : Body
} derive(Show, Eq)

///|
/// HCL body as a sequence of attributes and nested blocks.
pub(all) struct Body {
  items : Array[BodyItem]
} derive(Show, Eq)

///|
/// Top-level or nested HCL item.
pub(all) enum BodyItem {
  Attribute(Attribute)
  Block(Block)
} derive(Show, Eq)

///|
/// `key = value` item.
pub(all) struct Attribute {
  key : String
  value : Expression
  pos : Position
} derive(Show, Eq)

///|
/// `type [labels...] { ... }` item.
pub(all) struct Block {
  type_ : String
  labels : Array[String]
  body : Body
  pos : Position
} derive(Show, Eq)

///|
/// HCL expression values parsed by this package.
pub(all) enum Expression {
  String(String)
  Number(Double)
  Bool(Bool)
  Null
  List(Array[Expression])
  Object(Map[String, Expression])
  Identifier(String)
} derive(Show, Eq)
