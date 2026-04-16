///|
pub(all) struct Document {
  body : Body
} derive(Show, Eq)

///|
pub(all) struct Body {
  items : Array[BodyItem]
} derive(Show, Eq)

///|
pub(all) enum BodyItem {
  Attribute(Attribute)
  Block(Block)
} derive(Show, Eq)

///|
pub(all) struct Attribute {
  key : String
  value : Expression
} derive(Show, Eq)

///|
pub(all) struct Block {
  type_ : String
  labels : Array[String]
  body : Body
} derive(Show, Eq)

///|
pub(all) enum Expression {
  String(String)
  Number(Double)
  Bool(Bool)
  Null
  List(Array[Expression])
  Object(Map[String, Expression])
  Identifier(String)
} derive(Show, Eq)
