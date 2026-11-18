open Ast
open Utils

let generate_legal_sequences csl_ast max_depth =
  let all_transitions_with_all_commands_and_args = get_src_dst_auth_levels_ids_to_tuple_cmd_args csl_ast in
  let initial_auth_level_id = csl_ast.csl_ast_initial_auth_level_id in
  let commands_ending = csl_ast.csl_ast_commands_ending in

  let used_transitions_for_legal_sequences_generation =
    let transitions_for_the_next_step = ref IntSet.empty in

    let rec aux = function
      | 0 ->
        let all_transitions_from_the_initial_level = Hashtbl.fold (fun current_transition _ result ->
          let (src, _) = current_transition in

          if src == initial_auth_level_id then
            current_transition :: result
          else
            result
        ) all_transitions_with_all_commands_and_args [] in

        let _ = List.iter (fun (_, dst) ->
          transitions_for_the_next_step := IntSet.add dst !transitions_for_the_next_step
        ) all_transitions_from_the_initial_level in

        [(0, all_transitions_from_the_initial_level)]
      | current_depth ->
        let transitions_from_the_previous_layer = aux (current_depth - 1) in

        let all_transitions_from_this_level = IntSet.fold (fun src_transitions_for_the_next_step result ->
          Hashtbl.fold (fun current_transition _ result ->
            let (src, _) = current_transition in

            if src == src_transitions_for_the_next_step then
              current_transition :: result
            else
              result
          ) all_transitions_with_all_commands_and_args [] @ result
        ) !transitions_for_the_next_step [] in

        let _ = transitions_for_the_next_step := IntSet.empty in

        let _ = List.iter (fun (_, dst) ->
          transitions_for_the_next_step := IntSet.add dst !transitions_for_the_next_step
        ) all_transitions_from_this_level in

        (current_depth, all_transitions_from_this_level) :: transitions_from_the_previous_layer
    in

    aux (max_depth - 1)
  in

  let random_seed_base = int_of_float (Unix.time ()) in
  let random_seed_increment = ref 0 in

  let arg_value_to_concrete_string command = function
    | Anything ->
        let first_separator = List.nth csl_ast.csl_ast_arg_separator.arg_separator_chars 0 in
        let number_of_separators = command.command_arity - 1 in

        let _ = incr random_seed_increment in

        let current_seed = random_seed_base + !random_seed_increment in

        Utils.RandomStringGenerator.generate_random_string ~random_seed:(Some current_seed) ~generation_mode:(Utils.RandomStringGenerator.Text_Only_With_Separator (number_of_separators, first_separator)) ()
    | Value v -> v
  in

  let command_arg_to_string (command, arg_opt) =
    match arg_opt, command.command_subcommand, command.command_appendix with
      | None, None, None -> command.command_name
      | None, None, Some appendix -> command.command_name ^ " " ^ appendix
      | None, Some subcommand, None -> command.command_name ^ " " ^ subcommand
      | None, Some subcommand, Some appendix -> command.command_name ^ " " ^ subcommand ^ " " ^ appendix
      | Some arg, None, None -> command.command_name ^ " " ^ arg_value_to_concrete_string command arg.arg_value
      | Some arg, None, Some appendix -> command.command_name ^ " " ^ arg_value_to_concrete_string command arg.arg_value ^ " " ^ appendix
      | Some arg, Some subcommand, None -> command.command_name ^ " " ^ subcommand ^ " " ^ arg_value_to_concrete_string command arg.arg_value
      | Some arg, Some subcommand, Some appendix -> command.command_name ^ " " ^ subcommand ^ " " ^ arg_value_to_concrete_string command arg.arg_value ^ " " ^ appendix
  in

  let all_transitions_with_string_commands = Hashtbl.fold (fun transition commands_args result ->
    let commands_args_as_str = List.map command_arg_to_string commands_args in

    (transition, commands_args_as_str) :: result
  ) all_transitions_with_all_commands_and_args [] in

  let rec combine_commands current_depth =
    let (_, transitions_for_the_current_depth) = List.find (fun (depth, _) ->
      depth == current_depth
    ) used_transitions_for_legal_sequences_generation in

    let commands_for_the_current_depth = List.fold_left (fun result current_transition ->
      let (src, dst) = current_transition in
      
      List.find (fun ((src_cmd, dst_cmd), _) ->
        src == src_cmd && dst == dst_cmd
      ) all_transitions_with_string_commands :: result
    ) [] transitions_for_the_current_depth in

    match current_depth with
      | 0 ->
          List.fold_left (fun result (transition, current_commands) ->
            List.fold_left (fun result current_command ->
              (transition, current_command) :: result
            ) result current_commands
          ) [] commands_for_the_current_depth
      | _ ->
          let previous_sequences = combine_commands (current_depth - 1) in

          List.fold_left (fun result current_previous_sequence ->
            let ((prev_seq_src, prev_seq_dst), prev_seq) = current_previous_sequence in

            let commands_to_add_to_the_previous_sequence = List.filter (fun ((src, _), _) ->
              src == prev_seq_dst
            ) commands_for_the_current_depth in

            List.fold_left (fun new_commands_sequences current_commands_to_add ->
              let ((_, commands_to_add_dst), commands_to_add_commands) = current_commands_to_add in

              List.fold_left (fun new_sequences current_command_to_add ->
                let new_comand_sequence = prev_seq ^ commands_ending ^ current_command_to_add in

                ((prev_seq_src, commands_to_add_dst), new_comand_sequence) :: new_sequences
              ) new_commands_sequences commands_to_add_commands
            ) result commands_to_add_to_the_previous_sequence
          ) [] previous_sequences @ previous_sequences
  in

  let raw_combined_commands = combine_commands (max_depth - 1) in

  let mapped_combined_commands = List.map (fun ((_, _), command_sequence) ->
    command_sequence
  ) raw_combined_commands in

  (* To prevent some f*cking problems, as used in AdversarialGenerator *)
  let all_legal_sequences = List.map (fun legal_sequence ->
    legal_sequence ^ commands_ending ^ commands_ending
  ) mapped_combined_commands in

  let undefined_commands_sequences =
    let max_depth_range = range (max_depth - 1) in

    List.fold_left (fun result current_depth ->
      let current_depth_range = range current_depth in

      List.fold_left (fun current_command_sequence _ ->
        current_command_sequence ^ "aaaa" ^ commands_ending
      ) "" current_depth_range :: result
    ) [] max_depth_range
  in

  let undefined_commands_sequences_with_extra_carriage_return = List.map (fun current_sequence ->
    current_sequence ^ "\n"
  ) undefined_commands_sequences in

  all_legal_sequences @ undefined_commands_sequences_with_extra_carriage_return