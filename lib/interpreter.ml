open Core

let error msg =
  Error msg

let interpret ast =
  let open Ast in
  let open Core.Result.Monad_infix in
  let eval_literal l =
    match l with
    | Literal.Number i -> Ok (Value.Number i)
    | Literal.Boolean b -> Ok (Value.Boolean b)
  in

  let rec eval_expression e =
    match e with
    | Expression.Literal l -> eval_literal l
    | Expression.Binary (lhs, op, rhs) -> begin
      eval_expression lhs >>= fun lhs ->
      eval_expression rhs >>= fun rhs ->
      match (lhs, rhs) with
      | (Value.Number lhs, Value.Number rhs) -> begin
        let open Binary_operator in
        match op with
        | Plus -> Ok (Value.Number (lhs + rhs))
        | Minus -> Ok (Value.Number (lhs - rhs))
        | Times -> Ok (Value.Number (lhs * rhs))
        | Divide -> Ok (Value.Number (lhs / rhs))
        | Equal -> Ok (Value.Boolean (lhs = rhs))
        | Less_than -> Ok (Value.Boolean (lhs < rhs))
      end
      | _ -> error "Invalid arithmetic operation" (* TODO: better error message *)
    end
    | Expression.Logical (lhs, op, rhs) -> begin
      eval_expression lhs >>= fun lhs ->
      eval_expression rhs >>= fun rhs ->
      match (lhs, rhs) with
      | (Value.Boolean lhs, Value.Boolean rhs) -> begin
        let open Logical_operator in
        match op with
        | And -> Ok (Value.Boolean (lhs && rhs))
        | Or -> Ok (Value.Boolean (lhs || rhs))
      end
      | _ -> error "Invalid logical operation" (* TODO: better error message *)
    end
    | Expression.Unary (op, rhs) -> begin
      eval_expression rhs >>= fun rhs ->
      let open Unary_operator in
      match (op, rhs) with
      | (Positive, Value.Number rhs) -> Ok (Value.Number (-rhs))
      | (Negate_number, Value.Number rhs) -> Ok (Value.Number (rhs))
      | (Negate_bool, Value.Boolean rhs) -> Ok (Value.Boolean (not rhs))
      | _ -> error "Invalid unary operation" (* TODO: better error message *)
      end
    | Expression.Conditional (cond, if_t, if_f) -> begin
      eval_expression cond >>= fun cond ->
      match cond with
      | Value.Boolean cond ->
        if cond then
          eval_expression if_t
        else
          eval_expression if_f
      | _ -> error "Invalid condition in conditional"

    end
  in

  let eval_statement s =
    match s with
    | Statement.Expression_statement e ->
      eval_expression e
  in
  
  let eval_program p =
    match p with
    | Program.Program s ->
      eval_statement s
  in
  
  eval_program ast
