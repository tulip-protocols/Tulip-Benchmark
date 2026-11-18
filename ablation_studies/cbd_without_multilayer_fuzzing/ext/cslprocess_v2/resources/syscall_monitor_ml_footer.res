type string_distance_algorithm =
  | Jaro
  | Levenstein_Limited

let string_distance_algorithm_choice = Levenstein_Limited
let syscalls_distance_threshold = 0.80

type commands_behavior =
  | Normal
  | Strange

type problematic_command =
  | Undefined
  | Command of string

module StringSet = Set.Make(String)
module IntSet = Set.Make(Int)

let file2string_list file_name =
  if not(Sys.file_exists file_name) then
    raise (FileNotFoundException file_name);

  let file_channel = In_channel.open_bin file_name in
  let file_content = In_channel.input_all file_channel in
  let file_string_list = String.split_on_char '\n' file_content in

  In_channel.close file_channel;

  file_string_list

let char2string c =
  String.make 1 c

let remove_prefix command ~prefix =
  match String.starts_with command ~prefix with
    | false -> command
    | true ->
        let command_length = String.length command in
        let prefix_length = String.length prefix in

        String.sub command prefix_length (command_length - prefix_length)

let escape_regex_str regex_str =
  let espaced_quotes = Str.global_replace (Str.regexp "\"") "\\\"" regex_str in

  espaced_quotes

let parse_syscalls_whitelist whitelist_file_path =
  let whitelist_file_content = file2string_list whitelist_file_path in

  let result = Hashtbl.create 1 in

  let _ = List.fold_left (fun current_command current_whitelist_file_line ->
    if String.ends_with ~suffix:":" current_whitelist_file_line == true then
      let current_whitelist_file_line_length = String.length current_whitelist_file_line in

      let command =
        let raw_command = String.sub current_whitelist_file_line 0 (current_whitelist_file_line_length - 1) in

        if String.equal "<other_commands>" raw_command == false then
          raw_command
        else
          "other_commands"
      in

      if commands_are_case_sensitive == false then
        String.lowercase_ascii command
      else
        command
    else if String.equal current_whitelist_file_line "" == false then
      let transformed_current_whitelist_file_line =
        let current_whitelist_file_line_without_spaces = remove_prefix ~prefix:"    " current_whitelist_file_line in
        let current_whitelist_file_line_without_spaces_length = String.length current_whitelist_file_line_without_spaces in

        let current_whitelist_file_line_without_useless_characters = String.sub current_whitelist_file_line_without_spaces 0 (current_whitelist_file_line_without_spaces_length - 1) in

        let raw_address_regex = Str.regexp "<raw_address>" in
        let current_whitelist_file_line_without_useless_characters_with_address_regex = Str.global_replace raw_address_regex "0x[0-9a-f]+" current_whitelist_file_line_without_useless_characters in

        let int_regex = Str.regexp "<int>" in
        let current_whitelist_file_line_without_useless_characters_with_address_and_int_regexes = Str.global_replace int_regex "[0-9]+" current_whitelist_file_line_without_useless_characters_with_address_regex in

        let escaped = escape_regex_str current_whitelist_file_line_without_useless_characters_with_address_and_int_regexes in

        escaped ^ " *=.*"
      in

      match Hashtbl.find_opt result current_command with
        | None ->
          let new_set = StringSet.singleton transformed_current_whitelist_file_line in
          let _ = Hashtbl.add result current_command new_set in

          current_command
        | Some s ->
          let new_set = StringSet.add transformed_current_whitelist_file_line s in
          let _ = Hashtbl.replace result current_command new_set in

          current_command
    else
      current_command
  ) "" whitelist_file_content in

  result

let parse_syscalls_file syscalls_file_path issued_commands =
  let syscalls_file_content = file2string_list syscalls_file_path in

  (* We want to remove the first and the last line of the syscall file.
   * They should be like :
   * - [ Process PID=46486 runs in 32 bit mode. ]
   * - +++ exited with 1 +++ *)
  let syscalls_file_content_without_header_and_footer = List.filteri (fun i file_line ->
    (i != 0) && (i < List.length syscalls_file_content)
  ) syscalls_file_content in

  (* We keep only syscalls that are in the "syscall_names" array *)
  let syscalls_file_content_with_only_interesting_syscalls = List.filter (fun syscall ->
    let is_a_read_syscall = String.starts_with ~prefix:"read(0," syscall in
    let is_a_write_syscall = String.starts_with ~prefix:"write(1," syscall in
    let is_a_writev_syscall = String.starts_with ~prefix:"writev(" syscall in

    let is_ignored = List.exists (fun ignored_syscall_csl ->
      Str.string_match ignored_syscall_csl syscall 0
    ) ignored_syscalls in

    let is_a_refused_command_related_syscall = List.exists (fun refused_command_related_syscall_csl ->
      Str.string_match refused_command_related_syscall_csl syscall 0
    ) refused_syscalls in

    let is_a_full_ascii_write_syscall_if_it_is_a_write_syscall =
      match is_a_write_syscall with
        | false -> true
        | true ->
            let full_ascii_write_syscall_regex_str = "write(1, \"[a-zA-Z0-9 +-]+.*\\\\n" in
            let full_ascii_write_syscall_regex = Str.regexp full_ascii_write_syscall_regex_str in

            Str.string_match full_ascii_write_syscall_regex syscall 0
    in

    ((is_a_read_syscall || is_a_write_syscall || is_a_writev_syscall) || (not is_ignored && is_a_refused_command_related_syscall)) && is_a_full_ascii_write_syscall_if_it_is_a_write_syscall
  ) syscalls_file_content_without_header_and_footer in

  let issued_commands_with_ids = List.mapi (fun i command ->
    (command, i)
  ) issued_commands in

  let (commands_with_ids, empty_commands) = match ignore_empty_commands with
    | false -> (issued_commands_with_ids, IntSet.empty)
    | true ->
      let empty_commands_set = ref IntSet.empty in

      let empty_command_regex = Str.regexp "^ *$" in
      let empty_command_regex_tabs = Str.regexp "^\r*$" in

      let commands_without_empty_commands = List.filter (fun (command, command_id) ->
        let empty_predicate = not (Str.string_match empty_command_regex command 0) && not (Str.string_match empty_command_regex_tabs command 0) in

        if empty_predicate == true then
          true
        else
          let new_empty_commands_set = IntSet.(!empty_commands_set |> add command_id) in

          let _ = empty_commands_set := new_empty_commands_set in

          false
      ) issued_commands_with_ids in

      (commands_without_empty_commands, !empty_commands_set)
  in

  let number_of_commands = List.length commands_with_ids in

  let number_of_answers_syscalls = List.fold_left (fun res current_syscall ->
    if String.starts_with ~prefix:"read(0, " current_syscall == false then
      res + 1
    else
      res
  ) 0 syscalls_file_content_with_only_interesting_syscalls in

  (* We ignore last commands that have no associated syscalls *)
  let filtered_commands = if number_of_commands > number_of_answers_syscalls then
    List.filteri (fun i _ ->
      i < number_of_answers_syscalls
    ) commands_with_ids
  else
    commands_with_ids
  in

  let number_of_filtered_commands = List.length filtered_commands in

  let syscalls_without_ignored_commands_if_applicable_with_end_marker = syscalls_file_content_with_only_interesting_syscalls @ ["---END---"] in

  let (reversed_answers_syscalls_with_associated_command_id, _) = List.fold_left (fun (result, (saw_first_read, last_associated_syscall_to_current_read, saw_write_for_the_previous_command, write_for_the_previous_command_is_a_refused_syscall, current_command_id)) current_syscall -> (* Reversed because of the usage of (::) *)
    if String.starts_with ~prefix:"read(0, " current_syscall then
      begin
        let new_command_id = current_command_id + 1 in

        if saw_write_for_the_previous_command == true then
          let new_result =
            if saw_first_read == true then
              begin
                if String.equal last_associated_syscall_to_current_read "" == false then
                  (last_associated_syscall_to_current_read, current_command_id) :: result
                else
                  ("EMPTY", current_command_id) :: result
              end
            else
              result
          in

          (new_result, (true, "", false, false, new_command_id))
        else
          (result, (saw_first_read, current_syscall, saw_write_for_the_previous_command, false, new_command_id))
      end
    else if (String.starts_with ~prefix:"write(1, " current_syscall == true) || (String.starts_with ~prefix:"writev" current_syscall) then
      if (write_for_the_previous_command_is_a_refused_syscall == false) then
        let current_syscall_is_a_refused_syscall = (List.exists (fun refused_syscall_csl ->
          Str.string_match refused_syscall_csl current_syscall 0
        ) refused_syscalls) && (String.equal current_syscall "EMPTY" == false) in (* Empty syscalls are considered as refused *)

        if current_syscall_is_a_refused_syscall then
          (result, (saw_first_read, current_syscall, true, true, current_command_id))
        else
          (result, (saw_first_read, current_syscall, true, false, current_command_id))
      else
        (result, (saw_first_read, last_associated_syscall_to_current_read, saw_write_for_the_previous_command, write_for_the_previous_command_is_a_refused_syscall, current_command_id))
    else if String.equal "---END---" current_syscall == true then
      let new_result = (last_associated_syscall_to_current_read, current_command_id) :: result in

      (new_result, (saw_first_read, current_syscall, false, false, current_command_id))
    else
      (result, (saw_first_read, last_associated_syscall_to_current_read, saw_write_for_the_previous_command, write_for_the_previous_command_is_a_refused_syscall, current_command_id))
  ) ([], (false, "", true, false, -1)) syscalls_without_ignored_commands_if_applicable_with_end_marker in

  let answers_syscalls = List.rev reversed_answers_syscalls_with_associated_command_id in

  (* We fit the number of answer syscalls to the number of commands, and remove syscalls that do not begin with "write(1," or "writev", and remove syscalls related to empty commands if applicable *)
  let filtered_answers_syscalls =
    let count_of_kept_commands = ref 0 in

    List.filter (fun (syscall, command_id) ->
      if (String.starts_with ~prefix:"write(1," syscall) || (String.starts_with ~prefix:"writev" syscall) then
        let associated_command_opt = List.find_opt (fun (_, current_issued_command_id) ->
          command_id = current_issued_command_id
        ) issued_commands_with_ids in

        match associated_command_opt with
          | None -> false
          | Some (associated_command, _) ->
              if IntSet.mem command_id empty_commands == false then
                if !count_of_kept_commands <= number_of_filtered_commands then
                  let _ = count_of_kept_commands := !count_of_kept_commands + 1 in

                  true
                else
                  false
              else
                let empty_command_regex = Str.regexp "^ *$" in
                let empty_command_regex_tabs = Str.regexp "^\r*$" in

                let associated_command_is_empty = (Str.string_match empty_command_regex associated_command 0) || (Str.string_match empty_command_regex_tabs associated_command 0) in

                if associated_command_is_empty then
                  false
                else
                  if !count_of_kept_commands <= number_of_filtered_commands then
                    let _ = count_of_kept_commands := !count_of_kept_commands + 1 in
  
                    true
                  else
                    false
      else
        false
    ) answers_syscalls
  in

  let number_of_filtered_answers_syscalls = List.length filtered_answers_syscalls in

  let filtered_commands_after_filtered_syscalls = List.filteri (fun i _ ->
    if i < number_of_filtered_answers_syscalls then
      true
    else
      false
  ) filtered_commands in

  let commands_to_syscalls = List.map2 (fun command syscall ->
    (command, syscall)
  ) filtered_commands_after_filtered_syscalls filtered_answers_syscalls in

  (* We remove refused commands to return only accepted commands *)
  let commands_to_syscalls_without_refused_commands =
    let normal_commands_to_syscalls_without_refused_commands = List.filter (fun (_, (syscall, _)) ->
      not (List.exists (fun refused_syscall_csl ->
        Str.string_match refused_syscall_csl syscall 0
      ) refused_syscalls) && (String.equal syscall "EMPTY" == false) (* Empty syscalls are considered as refused *)
    ) commands_to_syscalls in

    List.map (fun (command, syscall) ->
      (command, syscall)
    ) normal_commands_to_syscalls_without_refused_commands
  in

  (* let _ =
    let _ = Printf.eprintf "BEGIN BEGIN BEGIN\n" in

    let _ = Printf.eprintf "NUMBER OF COMMANDS: %d\n" number_of_commands in

    let _ = List.iter (fun s -> Printf.eprintf "%s\n" s) filtered_commands_after_filtered_syscalls in
    let _ = List.iter (fun s -> Printf.eprintf "%s\n" s) filtered_answers_syscalls in

    let _ = Printf.eprintf "END END END END\n" in ()
  in *)

  List.map (fun ((command, _), _) ->
    command
  ) commands_to_syscalls_without_refused_commands

let rec range = function
  | 0 -> [0]
  | n -> (n - 1) :: range (n - 1)

let jaro a b = (* Implemented as https://fr.wikipedia.org/wiki/Distance_de_Jaro-Winkler *)
  if String.equal a b then
    1.0
  else
    let length_a = String.length a in
    let length_b = String.length b in

    let max_distance = floor ((Float.of_int (max length_a length_b)) /. 2.0) -. 1.0 in

    let m =
      let (result, _) = String.fold_left (fun (result, i_a) current_char_a ->
        let (m_for_current_char_a, _) = String.fold_left (fun (m_for_current_char_a, i_b) current_char_b ->
          if m_for_current_char_a != 1 then
            let min_i_b = i_a - Int.of_float (max_distance /. 2.0) in
            let max_i_b = i_a + Int.of_float (max_distance /. 2.0) in

            if ((i_b >= 0) && (i_b >= min_i_b) && (i_b <= max_i_b) && (current_char_a == current_char_b)) then
              (1, i_b + 1)
            else
              (m_for_current_char_a, i_b + 1)
          else
            (m_for_current_char_a, i_b + 1)
        ) (0, 0) b in

        (result + m_for_current_char_a, i_a + 1)
      ) (0, 0) a in

      result
    in

    if m == 0 then
      0.0
    else
      let t =
        let min_length = min length_a length_b in
        let range_min_length = range min_length in

        let demi_transpostions = List.fold_left (fun result i ->
          let current_char_a = String.get a i in
          let current_char_b = String.get b i in

          if current_char_a != current_char_b then
            result + 1
          else
            result
        ) 0 range_min_length in

        demi_transpostions / 2
      in

      let m_float = Float.of_int m in

      let result = (1.0 /. 3.0) *. ((m_float /. (Float.of_int length_a)) +. (m_float /. (Float.of_int length_b)) +. ((m_float -. (Float.of_int t)) /. m_float)) in

      if result < 0.0 then
        0.0
      else
        result

let rec range2 limit n =
  if (n <= limit) then
    []
  else
    (n - 1) :: range2 limit (n - 1)

(* Pseudocode implementation: (https://en.wikipedia.org/wiki/Levenshtein_distance)
  function LevenshteinDistance(char s[1..m], char t[1..n]):
  // for all i and j, d[i,j] will hold the Levenshtein distance between
  // the first i characters of s and the first j characters of t
  declare int d[0..m, 0..n]
 
  set each element in d to zero
 
  // source prefixes can be transformed into empty string by
  // dropping all characters
  for i from 1 to m:
    d[i, 0] := i
 
  // target prefixes can be reached from empty source prefix
  // by inserting every character
  for j from 1 to n:
    d[0, j] := j
 
  for j from 1 to n:
    for i from 1 to m:
      if s[i] = t[j]:
        substitutionCost := 0
      else:
        substitutionCost := 1

      d[i, j] := minimum(d[i-1, j] + 1,                   // deletion
                         d[i, j-1] + 1,                   // insertion
                         d[i-1, j-1] + substitutionCost)  // substitution
 
  return d[m, n]
*)
let levenstein a b =
  let min3 : int -> int -> int -> int = fun i j k ->
    min (min i j) k
  in

  let m = String.length a in
  let n = String.length b in

  let d = Array.init (m + 1) (fun i ->
    Array.make (n + 1) 0
  ) in

  let range_1_m = List.rev (range2 1 (m + 1)) in
  let range_1_n = List.rev (range2 1 (n + 1)) in

  let _ = List.iter (fun a_i ->
    d.(a_i).(0) <- a_i
  ) range_1_m in

  let _ = List.iter (fun b_j ->
    d.(0).(b_j) <- b_j
  ) range_1_n in

  let _ = List.iter (fun b_j ->
    List.iter (fun a_i ->
      let char_a_i = String.get a (a_i - 1) in
      let char_b_j = String.get b (b_j - 1) in

      let substitution_cost =
        if Char.equal char_a_i char_b_j then
          0
        else
          1
      in

      d.(a_i).(b_j) <-
        min3 (d.(a_i - 1).(b_j) + 1) (d.(a_i).(b_j - 1) + 1) (d.(a_i - 1).(b_j - 1) + substitution_cost)
    ) range_1_m
  ) range_1_n in

  d.(m).(n)

(* Source: Section 3 of https://ev.fe.uni-lj.si/3-2025/Poljak.pdf *)
let levenstein_distance_limited a b =
  let levenstein_distance = levenstein a b in

  let length_a = String.length a in
  let length_b = String.length b in
  let max_string_length = max length_a length_b in

  1.00 -. (Float.of_int levenstein_distance /. Float.of_int max_string_length)

let get_string_distance_algorithm = function
  | Jaro -> jaro
  | Levenstein_Limited -> levenstein_distance_limited

(* WARNING : We assume that commands are read by a syscall like `read(0, "<My command>", ...)` *)
let does_not_use_only_authorized_syscalls_with_problematic_syscalls commands_list full_syscalls_file_path =
  let full_syscalls_file_content = file2string_list full_syscalls_file_path in

  let filtered_full_syscalls_file_content = List.filter (fun file_line ->
    let syscall_regex = Str.regexp "[a-z0-9]+(.*" in

    Str.string_match syscall_regex file_line 0
  ) full_syscalls_file_content in

  let problematic_syscalls = Hashtbl.create 0 in (* command -> problematic syscalls set *)
  let current_command_id = ref (-1) in
  let commands_list_length = List.length commands_list in

  let (is_suspicious, problematic_command) =
    if check_answers_when_looking_for_illegal_syscalls == true then
      let (is_suspicious, _, _, problematic_command, _) = List.fold_left (fun (is_suspicious, current_command, current_arg, problematic_command, saw_response_for_the_current_command) current_syscall ->
        let splited_current_syscall = String.split_on_char '(' current_syscall in
        let current_syscall_name = List.nth splited_current_syscall 0 in

        let is_current_syscall_sensitive = List.exists (fun syscall ->
          String.equal current_syscall_name syscall
        ) sensitive_syscalls in

        let sanitized_current_syscall =
          let unfinished_regex = Str.regexp " *<unfinished ...>" in

          Str.global_replace unfinished_regex ") = UNFINISHED" current_syscall
        in

        if String.equal current_syscall_name "read" then
          let splited_current_syscall_arguments = String.split_on_char ',' (List.nth splited_current_syscall 1) in
          let read_fd = int_of_string (List.nth splited_current_syscall_arguments 0) in

          if saw_response_for_the_current_command then
            begin
              if (read_fd == 0) && ((List.length commands_list > !current_command_id + 1) && (String.equal "\r" (List.nth commands_list (!current_command_id + 1)) == false)) then
                let _ = current_command_id := !current_command_id + 1 in

                if (!current_command_id < commands_list_length) then
                  let full_command = List.nth commands_list !current_command_id in
                  let splited_full_command = String.split_on_char arg_separator full_command in

                  let command = match commands_are_case_sensitive with
                    | true -> List.nth splited_full_command 0
                    | false -> String.lowercase_ascii (List.nth splited_full_command 0)
                  in

                  let arg = if List.length splited_full_command >= 2 then
                    List.nth splited_full_command 1
                  else
                    ""
                  in

                  if String.equal command "\n" == false then
                    (is_suspicious, command, arg, problematic_command, false)
                  else
                    (is_suspicious, "", "", problematic_command, saw_response_for_the_current_command)
                else
                  (is_suspicious, current_command, current_arg, problematic_command, saw_response_for_the_current_command)
              else
                (is_suspicious, "", "", problematic_command, saw_response_for_the_current_command)
            end
          else if read_fd == 0 then
            let full_command_opt = List.nth_opt commands_list (!current_command_id + 1) in

            match full_command_opt with
              | None -> (is_suspicious, "", "", problematic_command, saw_response_for_the_current_command)
              | Some full_command ->
                if String.equal full_command "" == true then
                  (is_suspicious, "", "", problematic_command, saw_response_for_the_current_command)
                else
                  (is_suspicious, current_command, current_arg, problematic_command, saw_response_for_the_current_command)
          else
            (is_suspicious, current_command, current_arg, problematic_command, saw_response_for_the_current_command)
        else if String.starts_with ~prefix:"write(1," current_syscall then
          (is_suspicious, "", "", problematic_command, true)
        else if is_current_syscall_sensitive == false then
          (is_suspicious, current_command, current_arg, problematic_command, saw_response_for_the_current_command)
        else if String.equal current_command "" == false then
          if is_suspicious == true then
            (is_suspicious, current_command, current_arg, problematic_command, saw_response_for_the_current_command)
          else
            let authorized_syscalls_for_this_command_option = Hashtbl.find_opt authorized_syscalls current_command in

            match authorized_syscalls_for_this_command_option with
              | Some authorized_syscalls_for_this_command ->
                  let new_is_suspicious =
                    let matches_authorized_syscalls =
                      not (List.exists (fun syscall ->
                        let current_authorized_syscall_regex = Str.regexp syscall in

                        Str.string_match current_authorized_syscall_regex sanitized_current_syscall 0
                      ) authorized_syscalls_for_this_command)
                    in

                    match matches_authorized_syscalls with
                      | false -> matches_authorized_syscalls
                      | true ->
                        not (List.exists (fun syscall ->
                          let response_code_regex = Str.regexp ").*=.*$" in

                          let syscall_without_response_code = Str.global_replace response_code_regex ")" syscall in
                          let sanitized_current_syscall_without_response_code = Str.global_replace response_code_regex ")" sanitized_current_syscall in

                          let distance_current_authorized_syscall = get_string_distance_algorithm string_distance_algorithm_choice syscall_without_response_code sanitized_current_syscall_without_response_code in

                          distance_current_authorized_syscall > syscalls_distance_threshold
                        ) authorized_syscalls_for_this_command)
                  in

                  let _ = if new_is_suspicious == true then
                    match Hashtbl.find_opt problematic_syscalls current_command with
                      | None ->
                        let set = StringSet.singleton sanitized_current_syscall in

                        Hashtbl.add problematic_syscalls current_command set
                      | Some problematic_syscalls_set_for_this_command ->
                        let new_set = StringSet.add sanitized_current_syscall problematic_syscalls_set_for_this_command in

                        Hashtbl.replace problematic_syscalls current_command new_set
                  in

                  let new_problematic_command = match is_suspicious, new_is_suspicious with
                    | true, _ | false, false -> problematic_command
                    | false, true -> Command (current_command ^ char2string arg_separator ^ current_arg)
                  in

                  (new_is_suspicious, current_command, current_arg, new_problematic_command, saw_response_for_the_current_command)
              | None ->
                  let authorized_syscalls_for_other_commands_option = Hashtbl.find_opt authorized_syscalls "other_commands" in

                  let new_is_suspicious = match authorized_syscalls_for_other_commands_option with
                    | None -> true
                    | Some authorized_syscalls_for_other_commands ->
                        let directly_found =
                          List.exists (fun syscall ->
                            let current_authorized_syscall_regex = Str.regexp syscall in

                            Str.string_match current_authorized_syscall_regex sanitized_current_syscall 0
                          ) authorized_syscalls_for_other_commands
                        in

                        if directly_found then
                          false
                        else
                          not (List.exists (fun syscall ->
                            let response_code_regex = Str.regexp ").*=.*$" in

                            let syscall_without_response_code = Str.global_replace response_code_regex ")" syscall in
                            let sanitized_current_syscall_without_response_code = Str.global_replace response_code_regex ")" sanitized_current_syscall in

                            let distance_current_authorized_syscall = get_string_distance_algorithm string_distance_algorithm_choice syscall_without_response_code sanitized_current_syscall_without_response_code in

                            distance_current_authorized_syscall > syscalls_distance_threshold
                          ) authorized_syscalls_for_other_commands)
                  in

                  let _ = if new_is_suspicious == true then
                    let result_other_commands_key = "other_commands (" ^ current_command ^ ")" in

                    match Hashtbl.find_opt problematic_syscalls result_other_commands_key with
                      | None ->
                        let set = StringSet.singleton sanitized_current_syscall in

                        Hashtbl.add problematic_syscalls result_other_commands_key set
                      | Some problematic_syscalls_set_for_this_command ->
                        let new_set = StringSet.add sanitized_current_syscall problematic_syscalls_set_for_this_command in

                        Hashtbl.replace problematic_syscalls result_other_commands_key new_set
                  in

                  let new_problematic_command = match is_suspicious, new_is_suspicious with
                    | true, _ | false, false -> problematic_command
                    | false, true -> Command (current_command ^ char2string arg_separator ^ current_arg)
                  in

                  (new_is_suspicious, "", "", new_problematic_command, saw_response_for_the_current_command)
        else
          (is_suspicious, "", "", problematic_command, saw_response_for_the_current_command)
      ) (false, "", "", Undefined, true) filtered_full_syscalls_file_content in

      (is_suspicious, problematic_command)
    else
      let (is_suspicious, _, _, problematic_command) = List.fold_left (fun (is_suspicious, current_command, current_arg, problematic_command) current_syscall ->
        let splited_current_syscall = String.split_on_char '(' current_syscall in
        let current_syscall_name = List.nth splited_current_syscall 0 in

        let is_current_syscall_sensitive = List.exists (fun syscall ->
          String.equal current_syscall_name syscall
        ) sensitive_syscalls in

        let sanitized_current_syscall =
          let unfinished_regex = Str.regexp " *<unfinished ...>" in

          Str.global_replace unfinished_regex ") = UNFINISHED" current_syscall
        in

        if String.equal current_syscall_name "read" then
          let splited_current_syscall_arguments = String.split_on_char ',' (List.nth splited_current_syscall 1) in
          let read_fd = int_of_string (List.nth splited_current_syscall_arguments 0) in

          if (read_fd == 0) && ((List.length commands_list > !current_command_id + 1) && (String.equal "\r" (List.nth commands_list (!current_command_id + 1)) == false)) then
            let _ = current_command_id := !current_command_id + 1 in

            if (!current_command_id < commands_list_length) then
              let full_command = List.nth commands_list !current_command_id in
              let splited_full_command = String.split_on_char arg_separator full_command in

              let command = match commands_are_case_sensitive with
                | true -> List.nth splited_full_command 0
                | false -> String.lowercase_ascii (List.nth splited_full_command 0)
              in

              let arg = if List.length splited_full_command >= 2 then
                List.nth splited_full_command 1
              else
                ""
              in

              if String.equal command "\n" == false then
                (is_suspicious, command, arg, problematic_command)
              else
                (is_suspicious, "---NONE---", "---NONE---", problematic_command)
            else
              (is_suspicious, current_command, current_arg, problematic_command)
          else
            (is_suspicious, "---NONE---", "---NONE---", problematic_command)
        else if String.starts_with ~prefix:"write(1," current_syscall then
          (is_suspicious, "---NONE---", "---NONE---", problematic_command)
        else if is_current_syscall_sensitive == false then
          (is_suspicious, current_command, current_arg, problematic_command)
        else if String.equal current_command "---NONE---" == false then
          if is_suspicious == true then
            (is_suspicious, current_command, current_arg, problematic_command)
          else
            let authorized_syscalls_for_this_command_option = Hashtbl.find_opt authorized_syscalls current_command in

            match authorized_syscalls_for_this_command_option with
              | Some authorized_syscalls_for_this_command ->
                  let new_is_suspicious =
                    let matches_authorized_syscalls =
                      not (List.exists (fun syscall ->
                        let current_authorized_syscall_regex = Str.regexp syscall in

                        Str.string_match current_authorized_syscall_regex sanitized_current_syscall 0
                      ) authorized_syscalls_for_this_command)
                    in

                    match matches_authorized_syscalls with
                      | false -> matches_authorized_syscalls
                      | true ->
                        not (List.exists (fun syscall ->
                          let response_code_regex = Str.regexp ").*=.*$" in

                          let syscall_without_response_code = Str.global_replace response_code_regex ")" syscall in
                          let sanitized_current_syscall_without_response_code = Str.global_replace response_code_regex ")" sanitized_current_syscall in

                          let distance_current_authorized_syscall = get_string_distance_algorithm string_distance_algorithm_choice syscall_without_response_code sanitized_current_syscall_without_response_code in

                          distance_current_authorized_syscall > syscalls_distance_threshold
                        ) authorized_syscalls_for_this_command)
                  in

                  let _ = if new_is_suspicious == true then
                    match Hashtbl.find_opt problematic_syscalls current_command with
                      | None ->
                        let set = StringSet.singleton sanitized_current_syscall in

                        Hashtbl.add problematic_syscalls current_command set
                      | Some problematic_syscalls_set_for_this_command ->
                        let new_set = StringSet.add sanitized_current_syscall problematic_syscalls_set_for_this_command in

                        Hashtbl.replace problematic_syscalls current_command new_set
                  in

                  let new_problematic_command = match is_suspicious, new_is_suspicious with
                    | true, _ | false, false -> problematic_command
                    | false, true -> Command (current_command ^ char2string arg_separator ^ current_arg)
                  in

                  (new_is_suspicious, current_command, current_arg, new_problematic_command)
              | None ->
                  let authorized_syscalls_for_other_commands_option = Hashtbl.find_opt authorized_syscalls "other_commands" in

                  let new_is_suspicious = match authorized_syscalls_for_other_commands_option with
                    | None -> true
                    | Some authorized_syscalls_for_other_commands ->
                        let directly_found =
                          List.exists (fun syscall ->
                            let current_authorized_syscall_regex = Str.regexp syscall in

                            Str.string_match current_authorized_syscall_regex sanitized_current_syscall 0
                          ) authorized_syscalls_for_other_commands
                        in

                        if directly_found then
                          false
                        else
                          not (List.exists (fun syscall ->
                            let response_code_regex = Str.regexp ").*=.*$" in

                            let syscall_without_response_code = Str.global_replace response_code_regex ")" syscall in
                            let sanitized_current_syscall_without_response_code = Str.global_replace response_code_regex ")" sanitized_current_syscall in

                            let distance_current_authorized_syscall = get_string_distance_algorithm string_distance_algorithm_choice syscall_without_response_code sanitized_current_syscall_without_response_code in

                            distance_current_authorized_syscall > syscalls_distance_threshold
                          ) authorized_syscalls_for_other_commands)
                  in

                  let _ = if new_is_suspicious == true then
                    let result_other_commands_key = "other_commands (" ^ current_command ^ ")" in

                    match Hashtbl.find_opt problematic_syscalls result_other_commands_key with
                      | None ->
                        let set = StringSet.singleton sanitized_current_syscall in

                        Hashtbl.add problematic_syscalls result_other_commands_key set
                      | Some problematic_syscalls_set_for_this_command ->
                        let new_set = StringSet.add sanitized_current_syscall problematic_syscalls_set_for_this_command in

                        Hashtbl.replace problematic_syscalls result_other_commands_key new_set
                  in

                  let new_problematic_command = match is_suspicious, new_is_suspicious with
                    | true, _ | false, false -> problematic_command
                    | false, true -> Command (current_command ^ char2string arg_separator ^ current_arg)
                  in

                  (new_is_suspicious, "---NONE---", "---NONE---", new_problematic_command)
        else
          (is_suspicious, "---NONE---", "---NONE---", problematic_command)
      ) (false, "---NONE---", "---NONE---", Undefined) filtered_full_syscalls_file_content in

      (is_suspicious, problematic_command)
  in

  (is_suspicious, problematic_syscalls, problematic_command)

let string_set_hashtbl_merge a b =
  let _ = Hashtbl.iter (fun k v ->
    let k_in_a_opt = Hashtbl.find_opt a k in

    match k_in_a_opt with
      | None -> Hashtbl.add a k v
      | Some b_v ->
          let new_set = StringSet.union v b_v in

          Hashtbl.replace a k new_set
  ) b in

  a

let () =
  if (Array.length Sys.argv) < 4 then
    Printf.printf "ERROR : argc != 4\n"
  else
    ();

  let commands_files_path = Sys.argv.(1) in
  let reduced_syscalls_files_path = Sys.argv.(2) in
  let full_syscalls_files_path = reduced_syscalls_files_path in (* Now, we do not need two syscalls file per command sequence, but only one containing all recorded syscalls *)
  let output_dir = Sys.argv.(3) in

  let syscalls_whitelist_file_path =
    if Array.length Sys.argv == 4 then
      None
    else
      Some (Sys.argv.(4))
  in

  (* Handling whitelist *)
  let _ =
    match syscalls_whitelist_file_path with
      | None -> ()
      | Some file_path ->
        let parsed_whitelist = parse_syscalls_whitelist file_path in

        Hashtbl.iter (fun command syscalls_set ->
          let syscalls_set_as_list = StringSet.elements syscalls_set in
          let authorized_syscalls_for_the_current_command = Hashtbl.find_opt authorized_syscalls command in

          match authorized_syscalls_for_the_current_command with
            | None -> Hashtbl.add authorized_syscalls command syscalls_set_as_list
            | Some authorized_syscalls_for_the_current_command ->
              let new_syscalls_list = List.append syscalls_set_as_list authorized_syscalls_for_the_current_command in

              Hashtbl.replace authorized_syscalls command new_syscalls_list
        ) parsed_whitelist
  in

  let commands_files_path_is_a_directory = Sys.is_directory commands_files_path in

  let files = Sys.readdir reduced_syscalls_files_path in
  let filesList = Array.to_list files in

  let filesListFiltered = List.filter (fun file ->
    file <> ".state" && file <> "full"
  ) filesList in

  let strange_commands_output_dir = output_dir ^ "/" ^ "strange" in

  Sys.mkdir strange_commands_output_dir 0o755;

  List.iteri (fun i file ->
    let commands_file = if commands_files_path_is_a_directory == true then
      commands_files_path ^ "/" ^ file
    else
      commands_files_path
    in

    let syscalls_file = reduced_syscalls_files_path ^ "/" ^ file in
    let full_syscalls_file = full_syscalls_files_path ^ "/" ^ file in

    let raw_commands = file2string_list commands_file in

    let commands = match commands_prefix with
      | None -> raw_commands
      | Some p -> List.map (fun command ->
          remove_prefix command ~prefix:p
        ) raw_commands
    in

    let (suspicious, problematic_syscalls, problematic_command) = does_not_use_only_authorized_syscalls_with_problematic_syscalls commands full_syscalls_file in
    let accepted_commands = parse_syscalls_file syscalls_file commands in

    let all_problematic_syscalls = Hashtbl.create 0 in

    let behavior = match suspicious with
      | false -> Normal
      | true ->
        let _ = string_set_hashtbl_merge all_problematic_syscalls problematic_syscalls in

        Strange
    in

    if (List.length accepted_commands > 0) || (behavior == Strange) then
      let accepted_commands_as_string = match behavior with
        | Normal ->
            List.fold_left (fun result command ->
              result ^ command ^ "\n"
            ) "" accepted_commands
        | Strange ->
            List.fold_left (fun result command ->
              result ^ command ^ "\n"
            ) "" commands
      in

      let output_file_name = match behavior with
        | Normal -> (output_dir ^ "/" ^ (Filename.basename commands_file) ^ "_" ^ (Int.to_string i))
        | Strange -> (strange_commands_output_dir ^ "/" ^ (Filename.basename commands_file) ^ "_" ^ (Int.to_string i))
      in

      if String.length accepted_commands_as_string > 0 then
        let output_file_fd = Unix.openfile output_file_name [Unix.O_RDWR ; Unix.O_CREAT] 0o644 in
        let output_file_write_result = Unix.write output_file_fd (Bytes.of_string accepted_commands_as_string) 0 (String.length accepted_commands_as_string) in

        if output_file_write_result == 0 then
          Printf.printf "Unable to write in %s" output_file_name;

        Unix.close output_file_fd;

      if Hashtbl.length all_problematic_syscalls > 0 then
        let problematic_syscalls_description_str = Hashtbl.fold (fun command problematic_syscalls str ->
          let problematic_syscalls_as_list = StringSet.elements problematic_syscalls in

          str ^
            "File: " ^
            file ^
            "\n- " ^
            command ^
            "\n" ^
            List.fold_left (fun str2 problematic_syscall ->
              str2 ^ "-- " ^ problematic_syscall ^ "\n"
            ) "" problematic_syscalls_as_list
        ) all_problematic_syscalls "" in

        let _ = Printf.printf "Problematic syscalls (%s):\n%s\n" file problematic_syscalls_description_str in

        let report_file_path = strange_commands_output_dir ^ "/__report__.txt" in

        let report_file_fd = match Sys.file_exists report_file_path with
          | true -> Unix.openfile report_file_path [Unix.O_RDWR ; Unix.O_APPEND] 0o644
          | false -> Unix.openfile report_file_path [Unix.O_RDWR ; Unix.O_CREAT] 0o644
        in

        let _ = Unix.write report_file_fd (Bytes.of_string problematic_syscalls_description_str) 0 (String.length problematic_syscalls_description_str) in

        Unix.close report_file_fd
  ) filesListFiltered