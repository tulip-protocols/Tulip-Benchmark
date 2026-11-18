open Ast

(** Module embedding functions related to the generation of the adversarial sequences related to the CSL specification. *)

(** Type modeling an adversarial sequence *)
type adversarial_sequence = {
  adversarial_sequence_id: int; (** An unique ID of the adversarial sequence *)
  adversarial_sequence_composition_list: int list; (** The coposition list (i.e. precedences) of the adversarial sequence *)
  adversarial_sequence_content: string; (** The content of the adversarial sequence *)
}

(**
  Get all wildcarded commands ({b Adversarial} and {b non-adversarial}) used to generate the adversarial sequences, associated with an ID and the command AST node
*)
val generate_all_commands : csl_ast -> (int * string * command) list

(**
  [generate_adversarial_sequences_and_get_precedence_relation csl_ast max_depth] returns the generated adversarial sequences of maximal depth of [max_depth] associated to their commands ID, and with its unique ID

  For example, if an adversarial command ["USER milhouse"] has the ID 1, ad [max_depth = 2], an example of the returned value will be:
  {[
  {
    adversarial_sequence_id = 1;
    adversarial_sequence_composition_list = [1; 1; -1];
    advarsarial_sequence_content = "USER milhouse\nUSER milhouse\n"
  }
  ]}

  The remaining [-1] at the end of [adversarial_sequence_composition_list] is used by the algorithm, and correspond to the final state of the complementary automaton generated for the adversarial sequences generation.
*)
val generate_adversarial_sequences_and_get_precedence_relation : csl_ast -> int -> adversarial_sequence list