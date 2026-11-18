open Ast

(** Module embedding functions related to the generation of the legal sequences related to the CSL specification. *)

(**
    [generate_legal_sequences csl_ast max_depth] returns the generated legal sequences with the maximal depth [max_depth].
*)
val generate_legal_sequences : csl_ast -> int -> string list