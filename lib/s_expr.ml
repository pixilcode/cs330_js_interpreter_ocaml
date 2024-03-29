open Ast

type t =
  | Expr of t list
  | Atom of string

let string_atom s =
  Atom ("\"" ^ s ^ "\"")

let (
  boolean_keyword,
  number_keyword,
  unary_keyword,
  arithmetic_keyword,
  relational_keyword,
  logical_keyword,
  conditional_keyword,
  identifier_keyword,
  expression_statement_keyword,
  variable_declaration_keyword,
  program_keyword,
  call_keyword,
  function_keyword,
  function_body_keyword,
  block_keyword,
  return_keyword,
  assignment_keyword
) = (
  Atom "boolean",
  Atom "number",
  Atom "unary",
  Atom "arithmetic",
  Atom "relational",
  Atom "logical",
  Atom "conditional",
  Atom "identifier",
  Atom "expression_statement",
  Atom "variable_declaration",
  Atom "program",
  Atom "call",
  Atom "function",
  Atom "body",
  Atom "block",
  Atom "return",
  Atom "assignment"
)

let from_literal = function
  | Literal.Number n -> Expr [number_keyword; Atom (string_of_int n)]
  | Literal.Boolean b -> Expr [boolean_keyword; Atom (string_of_bool b)]
  
let rec from_expression = function
  | Expression.Literal l -> from_literal l
  | Expression.Binary (lhs, op, rhs) ->
    let keyword = match op with
      | Binary_operator.Plus
      | Binary_operator.Minus
      | Binary_operator.Times
      | Binary_operator.Divide -> arithmetic_keyword
      | Binary_operator.Equal
      | Binary_operator.Less_than -> relational_keyword
    in
    let op = Binary_operator.to_string op in
    let op = Atom op in
    let lhs = from_expression lhs in
    let rhs = from_expression rhs in
    Expr [keyword; op; lhs; rhs]
  | Expression.Unary (op, rhs) ->
    let op = Unary_operator.to_string op in
    let op = Atom op in
    let rhs = from_expression rhs in
    Expr [unary_keyword; op; rhs]
  | Expression.Logical (lhs, op, rhs) ->
    let op = Logical_operator.to_string op in
    let op = Atom op in
    let lhs = from_expression lhs in
    let rhs = from_expression rhs in
    Expr [logical_keyword; op; lhs; rhs]
  | Expression.Conditional (cond, then_, else_) ->
    let cond = from_expression cond in
    let then_ = from_expression then_ in
    let else_ = from_expression else_ in
    Expr [conditional_keyword; cond; then_; else_]
  | Expression.Identifier ident ->
    Expr [identifier_keyword; string_atom ident]
  | Expression.Call (fn, arg) ->
    let fn = from_expression fn in
    let arg = from_expression arg in
    Expr [call_keyword; fn; arg]
  | Expression.Function (arg_name, body) ->
    let body = List.map from_statement body in
    Expr [
      function_keyword;
      string_atom arg_name;
      Expr ([ function_body_keyword; ] @ body)
    ]
  | Expression.Assignment (ident, expression) ->
    let expression = from_expression expression in
    Expr [
      assignment_keyword;
      string_atom ident;
      expression
    ]

and from_statement = function
  | Statement.Expression_statement e -> Expr [ expression_statement_keyword; from_expression e ]
  | Statement.Variable_declaration decls ->
    let decls = List.map (fun (ident, e) ->
        Expr [ Expr [identifier_keyword; string_atom ident]; from_expression e ]
      ) decls in
    Expr ([ variable_declaration_keyword ] @ decls)
  | Statement.Block_statement statements ->
    let statements = List.map from_statement statements in
    Expr ([ block_keyword ] @ statements)
  | Statement.Return_statement expression ->
    let expression = from_expression expression in
    Expr [ return_keyword; expression ]

let from_program = function
  | Program.Program statements -> 
    let statement_list = List.map from_statement statements in
    Expr ([program_keyword] @ statement_list)

let from_ast = from_program

let from_value value =
  let value = 
    match value with
    | Value.Number i -> Expr [Atom "number"; Atom (string_of_int i)]
    | Value.Boolean b -> Expr [Atom "boolean"; Atom (string_of_bool b)]
    | Value.Function (arg_name, body, _env) -> Expr [
        Atom "function";
        Expr [Atom "arg_name"; string_atom arg_name];
        let body = List.map from_statement body in
        Expr ([Atom "body"] @ body)
      ]
    | Value.Void -> Expr [Atom "void"]
  in
  Expr [Atom "value"; value]

let from_error message =
  Expr [Atom "error"; string_atom message]

let rec to_string s_expr =
  match s_expr with
  | Expr l -> "(" ^ String.concat " " (List.map to_string l) ^ ")"
  | Atom s -> s