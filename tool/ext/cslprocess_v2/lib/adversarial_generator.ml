open Ast
open Utils

type adversarial_sequence = {
  adversarial_sequence_id: int;
  adversarial_sequence_composition_list: int list;
  adversarial_sequence_content: string;
}

let generate_all_commands csl_ast =
  let adversarial_commands_and_target_auth_levels_ids = get_commands_and_target_auth_levels_ids_for_an_auth_level_id csl_ast (-2) true in
  let non_adversarial_commands_and_target_auth_levels_ids = get_commands_and_target_auth_levels_ids_for_an_auth_level_id csl_ast (-2) false in
  let commands_ending = csl_ast.csl_ast_commands_ending in

  let i = ref (-1) in
  let saw_commands_string_set = ref StringSet.empty in

  let generate_command_list = List.fold_left (fun result (command, command_ast_node, _) ->
    let command_already_exists_in_result = StringSet.exists (fun current_command ->
      String.equal command current_command
    ) !saw_commands_string_set in

    match command_already_exists_in_result with
      | false ->
          let _ = i := !i + 1 in
          let _ = saw_commands_string_set := StringSet.add command !saw_commands_string_set in

          (!i, command ^ commands_ending, command_ast_node) :: result
      | true -> result
  ) [] in

  let adversarial_commands = generate_command_list adversarial_commands_and_target_auth_levels_ids in
  let non_adversarial_commands = generate_command_list non_adversarial_commands_and_target_auth_levels_ids in

  let result = adversarial_commands @ non_adversarial_commands in

  List.sort (fun (_, command1, _) (_, command2, _) ->
    String.compare command1 command2
  ) result

let inverted_auth_levels_transitions_to_stared_commands csl_ast =
  let auth_levels_transitions_to_stared_commands = get_auth_levels_transitions_to_stared_commands csl_ast in

  let auth_levels_ids = Hashtbl.fold (fun (src, dst) _ res ->
    let tab_src = if (src >= 0) && (List.exists (equals src) res == false) then
      src :: []
    else
      []
    in

    let tab_dst = if (dst >= 0) && (List.exists (equals dst) res == false) then
      dst :: []
    else
      []
    in

    res @ tab_src @ tab_dst
  ) auth_levels_transitions_to_stared_commands [] in

  let all_starred_commands = Hashtbl.fold (fun _ cmds res ->
    List.fold_left (fun res cmd ->
      if List.exists (equals cmd) res == false then
        cmd :: res
      else
        res
    ) res cmds
  ) auth_levels_transitions_to_stared_commands [] in

  let all_possible_transitions = List.fold_left (fun res src ->
    List.fold_left (fun res dst ->
      let tuple = (src, dst) in

      if List.exists (pairs_compare tuple) res == false then
        tuple :: res
      else
        res
    ) res auth_levels_ids
  ) [] auth_levels_ids in

  let sizeof_auth_levels_transitions_to_stared_commands = Hashtbl.length auth_levels_transitions_to_stared_commands in
  let res_base = Hashtbl.create sizeof_auth_levels_transitions_to_stared_commands in

  List.fold_left (fun res current_transition ->
    match Hashtbl.find_opt auth_levels_transitions_to_stared_commands current_transition with
      | None ->
        let _ = Hashtbl.add res current_transition all_starred_commands in

        res
      | Some legit_commands_for_this_transition ->
        let adversarial_commands_for_this_transition = minus_list all_starred_commands legit_commands_for_this_transition in

        let _ = Hashtbl.add res current_transition adversarial_commands_for_this_transition in

        res
  ) res_base all_possible_transitions

let rec internal_generate_adversarial_sequences csl_ast current_auth_level_id depth =
  let transitions_with_commands = get_auth_levels_transitions_to_stared_commands csl_ast in
  let inverted_transitions_with_commands = inverted_auth_levels_transitions_to_stared_commands csl_ast in
  let commands_ending = csl_ast.csl_ast_commands_ending in

  let auth_levels_transitions_to_stared_commands2starred_command_to_target_auth_levels auth_levels_transitions_to_stared_commands =
    let res = Hashtbl.create 1 in

    Hashtbl.iter (fun (_, dst) cmds ->
      List.iter (fun cmd ->
        match Hashtbl.find_opt res cmd with
          | None -> Hashtbl.add res cmd [dst];
          | Some dsts -> Hashtbl.replace res cmd (dst :: dsts);
      ) cmds
    ) auth_levels_transitions_to_stared_commands;

    res
  in

  let adversarial_commands_and_target_auth_levels_ids = auth_levels_transitions_to_stared_commands2starred_command_to_target_auth_levels transitions_with_commands in
  let non_adversarial_commands_and_target_auth_levels_ids = auth_levels_transitions_to_stared_commands2starred_command_to_target_auth_levels inverted_transitions_with_commands in
  let initial_auth_level_id = csl_ast.csl_ast_initial_auth_level_id in

  let result = match depth with
  | 0 ->
    let adversarial_commands = Hashtbl.fold (fun command _ res ->
      command :: res
    ) adversarial_commands_and_target_auth_levels_ids [] in

    if current_auth_level_id != initial_auth_level_id then
      let non_adversarial_commands = Hashtbl.fold (fun command _ res ->
        command :: res
      ) non_adversarial_commands_and_target_auth_levels_ids [] in

      adversarial_commands @ non_adversarial_commands
    else
      adversarial_commands
  | _ ->
    let sequences_fold_function command transitions adversarial_sequences =
      let command_with_ending = command ^ commands_ending in

      adversarial_sequences @ List.fold_left (fun new_sequences transition ->
        let previous_generation_step = internal_generate_adversarial_sequences csl_ast transition (depth - 1) in

        List.fold_left (fun sequences command ->
          (command_with_ending ^ command) :: sequences
        ) new_sequences previous_generation_step
      ) [] transitions
    in

    let adversarial_commands = Hashtbl.fold sequences_fold_function adversarial_commands_and_target_auth_levels_ids [] in
    let non_adversarial_commands = Hashtbl.fold sequences_fold_function non_adversarial_commands_and_target_auth_levels_ids [] in
  
    let res = adversarial_commands @ non_adversarial_commands in

    List.sort_uniq (fun a b ->
      String.compare a b
    ) res
  in

  (* We have to reverse the result because of this algoritm is recursive *)
  List.rev result

let generate_adversarial_sequences csl_ast max_depth =
  let initial_auth_level_id = csl_ast.csl_ast_initial_auth_level_id in
  let number_of_auth_levels = get_number_of_auth_levels csl_ast in
  let max_depth_caped_by_the_number_of_auth_levels = min max_depth number_of_auth_levels in
  let max_depth_caped_by_the_number_of_auth_levels_range = range (max_depth_caped_by_the_number_of_auth_levels - 1) in
  let commands_ending = csl_ast.csl_ast_commands_ending in

  let adversarial_sequences = List.fold_left (fun adversarial_sequences i ->
    adversarial_sequences @ internal_generate_adversarial_sequences csl_ast initial_auth_level_id i
  ) [] max_depth_caped_by_the_number_of_auth_levels_range in

  let remainder_layers = max_depth - max_depth_caped_by_the_number_of_auth_levels in

  let all_adversarial_sequences =
    if remainder_layers > 0 then
      let remaining_depths = range_min ~min:(max_depth_caped_by_the_number_of_auth_levels + 1) max_depth in

      let all_stared_commands_hashtbl = get_stared_commands_and_commands_with_args_from_and_to_auth_level_ids csl_ast in
      let all_stared_commands_keys_seq = Hashtbl.to_seq_keys all_stared_commands_hashtbl in

      let all_stared_commands = Seq.fold_left (fun res (current_command, _) ->
        current_command :: res
      ) [] all_stared_commands_keys_seq in

      List.fold_left (fun current_adversarial_sequences_for_the_current_depth current_depth ->
        current_adversarial_sequences_for_the_current_depth @ (List.fold_left (fun new_adversarial_sequences current_adversarial_sequence ->
          let new_adversarial_sequences_for_the_current_command = List.fold_left (fun res current_command ->
            (current_adversarial_sequence ^ commands_ending ^ current_command) :: res
          ) [] all_stared_commands in

          new_adversarial_sequences @ new_adversarial_sequences_for_the_current_command
        ) [] current_adversarial_sequences_for_the_current_depth)
      ) adversarial_sequences remaining_depths
    else
      adversarial_sequences
  in

  (* To prevent some f*cking problems *)
  List.map (fun adversarial_sequence ->
    adversarial_sequence ^ commands_ending
  ) all_adversarial_sequences

let generate_adversarial_sequences_and_get_precedence_relation csl_ast max_depth =
  let all_commands = generate_all_commands csl_ast in
  let adversarial_sequences = generate_adversarial_sequences csl_ast max_depth in
  let commands_ending = csl_ast.csl_ast_commands_ending in

  List.mapi (fun id adversarial_sequence ->
    let split_adversarial_sequence = String.split_on_char '\n' adversarial_sequence in

    let adversarial_sequence_commands_ids = List.map (fun adversarial_command ->
      let id_command_tuple_opt = List.find_opt (fun (_, command, _) ->
        String.equal (adversarial_command ^ "\n") command
      ) all_commands in

      let (id, _, _) = match id_command_tuple_opt with
        | None -> (-1, "", None)
        | Some id_command ->
            let (n_id, n_command, n_command_ast_node) = id_command in

            (n_id, n_command, Some n_command_ast_node)
      in

      id
    ) split_adversarial_sequence in

    let adversarial_sequence_with_prefix = match csl_ast.csl_ast_commands_prefix with
      | None -> adversarial_sequence
      | Some p ->
        let commands_with_prefix = List.map (fun c ->
          if (String.equal c "" == false) then
            p ^ c
          else
            c
        ) split_adversarial_sequence in

        str_join commands_ending commands_with_prefix
    in

    {
      adversarial_sequence_id = id;
      adversarial_sequence_composition_list = adversarial_sequence_commands_ids;
      adversarial_sequence_content = adversarial_sequence_with_prefix;
    }
  ) adversarial_sequences