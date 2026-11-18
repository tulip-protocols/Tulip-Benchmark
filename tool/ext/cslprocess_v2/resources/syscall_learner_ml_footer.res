module StringSet = Set.Make(String)

let file2string_list file_name =
  if not(Sys.file_exists file_name) then
    raise (FileNotFoundException file_name);

  let file_channel = In_channel.open_bin file_name in
  let file_content = In_channel.input_all file_channel in
  let file_string_list = String.split_on_char '\n' file_content in

  In_channel.close file_channel;

  file_string_list

let syscall_is_sensitive syscall =
  List.exists (fun current_sensitive_syscall ->
    String.starts_with ~prefix:current_sensitive_syscall syscall
  ) sensitive_syscalls

let sanitize_syscall syscall commands_args =
  let response_code_regex = Str.regexp " * =.*" in
  let left_hook_regex = Str.regexp "\[" in
  let right_hook_regex = Str.regexp "\]" in
  let raw_address_regex = Str.regexp "0x[0-9a-f]+" in
  let int_regex = Str.regexp "[0-9]+," in
  let comment_regex = Str.regexp "/\*.*\*/" in

  let step1 = Str.global_replace response_code_regex "" syscall in
  let step2 = Str.global_replace left_hook_regex "\[" step1 in
  let step3 = Str.global_replace right_hook_regex "\]" step2 in
  let step4 = Str.global_replace raw_address_regex "<raw_address>" step3 in
  let step5 = Str.global_replace int_regex "<int>," step4 in
  let sanitized_syscall = Str.global_replace comment_regex "/\*.*\*/" step5 in

  let sanitized_syscall_without_command_args = List.fold_left (fun result current_commands_arg ->
    let (new_result, _) = List.fold_left (fun (result, replaced_current_command_arg) current_command_arg_item ->
      let current_command_arg_item_match_regex_str = "^.*" ^ current_command_arg_item ^ ".*" in
      let current_command_arg_item_match_regex = Str.regexp current_command_arg_item_match_regex_str in
      let current_command_arg_item_regex = Str.regexp current_command_arg_item in

      if (replaced_current_command_arg == false) && (String.equal "" current_command_arg_item == false) && (Str.string_match current_command_arg_item_match_regex result 0) then
        let new_result = Str.global_replace current_command_arg_item_regex ".*" result in

        (new_result, true)
      else
        (result, replaced_current_command_arg)
    ) (result, false) current_commands_arg in

    new_result
  ) sanitized_syscall commands_args in

  if String.ends_with ~suffix:")" sanitized_syscall_without_command_args == false then
    sanitized_syscall_without_command_args ^ ")"
  else
    sanitized_syscall_without_command_args

(* Let the string "Coucou  toi ça va ?" and the call `combine_split_string ' ' (String.split_on_char ' ' str)`.
   The result will be ["Coucou  toi ça va ?"; ...; "Coucou  toi"; "Coucou "; "Coucou"]
*)
let combine_split_string sep split_str =
  let sep_as_str = String.make 1 sep in

  let (result, _) = List.fold_left (fun (result, (i, current_str)) current_str_split ->
    let new_str = match i with
      | 0 -> current_str_split
      | _ -> current_str ^ sep_as_str ^ current_str_split
    in

    let new_result = new_str :: result in
    let new_i = i + 1 in

    (new_result, (new_i, new_str))
  ) ([], (0, "")) split_str in

  result

let parse_syscalls_file commands_file_path syscalls_file_path =
  let commands_file_content = file2string_list commands_file_path in
  let syscalls_file_content = file2string_list syscalls_file_path in

  let commands_args = List.fold_left (fun result current_command ->
    let split_current_command = String.split_on_char arg_separator current_command in
    let split_current_command_args = List.tl split_current_command in

    let combined_current_command = combine_split_string arg_separator split_current_command in
    let combined_current_command_args = combine_split_string arg_separator split_current_command_args in

    (combined_current_command @ combined_current_command_args) :: result
  ) [] commands_file_content in

  let (reversed_answers_syscalls, _) = List.fold_left (fun (result, current_command_id) current_syscall -> (* Reversed because of the usage of (::) *)
    if String.starts_with ~prefix:"read(0, " current_syscall then
      let new_current_command_id = current_command_id + 1 in

      (result, new_current_command_id)
    else if (current_command_id > -1) && (syscall_is_sensitive current_syscall) then
      let sanitized_current_syscall = sanitize_syscall current_syscall commands_args in

      let new_result = (current_command_id, sanitized_current_syscall) :: result in

      (new_result, current_command_id)
    else
      (result, current_command_id)
  ) ([], -1) syscalls_file_content in

  let answers_syscalls = List.rev reversed_answers_syscalls in

  answers_syscalls

let () =
  let _ = if (Array.length Sys.argv) != 3 then
    Printf.printf "ERROR: argc != 3"
  in

  let commands_dir = Sys.argv.(1) in
  let syscalls_dir = Sys.argv.(2) in

  let commands_files = Sys.readdir commands_dir in
  let commands_files_list = Array.to_list commands_files in

  let parsed_syscall_files = List.fold_left (fun result current_command_file ->
    (* Invariant: Syscalls files have the same name as the commands files *)
    let current_command_file_path = commands_dir ^ "/" ^ current_command_file in
    let current_syscalls_file_path = syscalls_dir ^ "/" ^ current_command_file in

    let parsed_syscall_file = parse_syscalls_file current_command_file_path current_syscalls_file_path in

    let current_command_file_content = file2string_list current_command_file_path in

    let parsed_syscall_file_with_command_names = List.map (fun (command_index, syscall) ->
      let command_associated_with_command_index =
        if is_a_commands_protocol == false then
          "<all_commands>"
        else
          let command = List.nth current_command_file_content command_index in

          if (String.equal "aaaa" command) || (String.equal "aaaa\r" command) then
            "<other_commands>"
          else
            command
      in

      let split_command_associated_with_command_index = String.split_on_char arg_separator command_associated_with_command_index in
      let command_name_associated_with_command_index = List.nth split_command_associated_with_command_index 0 in

      (command_name_associated_with_command_index, syscall)
    ) parsed_syscall_file in

    parsed_syscall_file_with_command_names :: result
  ) [] commands_files_list in

  let flattened_parsed_syscalls_files = List.flatten parsed_syscall_files in

  let merged_flattened_parsed_syscalls_files = Hashtbl.create 1 in

  let _ = List.iter (fun (current_command, current_whitelisted_syscall) ->
    let inserted_syscalls_for_the_current_command = Hashtbl.find_opt merged_flattened_parsed_syscalls_files current_command in

    match inserted_syscalls_for_the_current_command with
      | None ->
          let current_whitelisted_syscall_singleton = StringSet.singleton current_whitelisted_syscall in

          Hashtbl.add merged_flattened_parsed_syscalls_files current_command current_whitelisted_syscall_singleton
      | Some whitelisted_syscalls_set ->
          let new_set_with_the_current_whitelisted_syscall = StringSet.add current_whitelisted_syscall whitelisted_syscalls_set in

          Hashtbl.replace merged_flattened_parsed_syscalls_files current_command new_set_with_the_current_whitelisted_syscall
  ) flattened_parsed_syscalls_files in

  Hashtbl.iter (fun command syscalls ->
    let syscalls_as_list = StringSet.elements syscalls in
    let syscalls_cardinal = StringSet.cardinal syscalls in

    let (syscalls_to_string, _) = List.fold_left (fun (result, i) current_syscall ->
      let new_result =
        if i < (syscalls_cardinal - 1) then
          result ^ "    " ^ current_syscall ^ ",\n"
        else
          result ^ "    " ^ current_syscall ^ ";\n"
      in

      (new_result, i + 1)
    ) ("", 0) syscalls_as_list in

    Printf.printf "%s:\n%s" command syscalls_to_string
  ) merged_flattened_parsed_syscalls_files