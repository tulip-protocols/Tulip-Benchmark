open Ast
open Exceptions
open Adversarial_generator
open Utils

val generate_seeds_for_all_commands : csl_ast -> (int * string list option * bool) list
val generate_seeds_for_adversarial_sequences : ?generated_adversarial_sequences_ids_opt: IntSet.t option -> csl_ast -> adversarial_sequence list -> (adversarial_sequence * string list) list