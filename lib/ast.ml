module Literal = struct
  type t =
    | Number of float
    | Boolean of bool
end

module Binary_operator = struct
  type t =
    | Plus
    | Minus
    | Times
    | Divide
    | Equal
    | Less_than
end

module Unary_operator = struct
  type t =
    | Negate_bool
    | Negate_number
    | Positive
end

module Logical_operator = struct
  type t =
    | And
    | Or
end

module Expression = struct
  type t =
    | Literal of Literal.t
    | Binary of t * Binary_operator.t * t
    | Unary of Unary_operator.t * t
    | Logical of t * Logical_operator.t * t
    | Conditional of t * t * t
end

module Statement = struct
  type t = Expression_statement of Expression.t
end

module Program = struct
  type t = Program of Statement.t
end

let from_json _json = failwith "Not implemented"