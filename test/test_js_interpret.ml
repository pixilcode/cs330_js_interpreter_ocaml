open Js_interpreter

(* run a test and print the result *)
let run_test (name, js) =
  print_endline ("--- " ^ name ^ " ---");

  let json = Util.run_acorn js in
  let ast = Parser.from_json_string json in
  let result = Interpreter.interpret ast in
  match result with
  | Ok (values, _env) ->
    let values = List.map S_expr.from_value values in
    let values = List.map S_expr.to_string values in
    List.iter print_endline values;
    print_newline ()
  | Error message ->
    let message = S_expr.from_error message in
    let message = S_expr.to_string message in
    print_endline message;
    print_newline ()

let tests = [
  ("simple_number", "1");
  ("unary", "!true");
  ("arithmetic", "1 + 2 - 3 * 4 / 6");
  ("relational", "1 < 2");
  ("equality", "1 == 2");
  ("logical", "true && false || false");
  ("short_circuit_or_logic", "1 == 1 || true + false");
  ("short_circuit_and_logic", "1 == 2 && true + false");
  ("error_boolean_1", "1 == 2 || 1 + 2");
  ("error_boolean_2", "1 == 1 && 1 + 2");
  ("error_boolean_3", "1 && true");
  ("error_boolean_4", "false || 3");
  ("error_arithmetic_1", "1 + true");
  ("error_arithmetic_2", "true - 1");
  ("error_arithmetic_3", "false * true");
  ("error_arithmetic_4", "true / true");
  ("error_unary_1", "!1");
  ("error_unary_2", "-true");
  ("error_unary_3", "+false");
  ("error_conditional", "1 ? 2 : 3");
  ("error_divide_by_zero", "6 / 0");

  (* local binding tests *)
  (
    "simple_binding", "
    let x = 0;
    x + 1
    "
  );

  (
    "undefined_variable", "
    let x = 0;
    y + 1
    "
  );

  (
    "multiple_definitions", "
    let x = 1;
    let y = 2;
    x + y
    "
  );

  (
    "multiple_definitions_same_decl", "
    let x = 1, y = 2;
    x + y
    "
  );

  (* function expression tests *)
  (
    "simple_function", "
    let f = function() { return 1 }
    f()
    "
  );
]

(* iterate over all the tests and run them *)
let () = List.iter run_test tests