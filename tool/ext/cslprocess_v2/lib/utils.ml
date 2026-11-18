let rec str_join sep = function
  | [] -> ""
  | str :: [] -> str
  | str :: remaining -> str ^ sep ^ (str_join sep remaining)

let rec range = function
  | 0 -> 0 :: []
  | max -> max :: range (max - 1)

let pairs_compare (a1, b1) (a2, b2) =
  a1 == a2 && b1 == b2

let equals a b =
  a == b

let minus_list a b =
  List.fold_left (fun res current_element ->
    if List.exists (equals current_element) b == false then
      current_element :: res
    else
      res
  ) [] a

let rec range_min ~min max =
  if max > min then
    max :: range_min ~min (max - 1)
  else
    min :: []

let str_transform str ~char_src ~char_dst =
  String.map (fun current_char ->
    if current_char == char_src then
      char_dst
    else
      current_char
  ) str

let rec transpose_list_list = function
  | [] -> []
  | [] :: next -> transpose_list_list next
  | (element :: next_list) :: next_list_list -> (element :: List.map List.hd next_list_list) :: transpose_list_list (next_list :: List.map List.tl next_list_list)

let str_split_on_multiple_char str chars =
  List.fold_left (fun result current_char ->
    List.fold_left (fun result current_str ->
      result @ String.split_on_char current_char current_str
    ) [] result
  ) [str] chars

module IntListHash = struct
  type t = int list

  let rec equal a b =
    match a, b with
      | [], [] -> true
      | _, [] | [], _ -> false
      | hd_a :: tl_a, hd_b :: tl_b ->
          if Int.equal hd_a hd_b then
            equal tl_a tl_b
          else
            false

  let hash l =
    let rec aux n current_hash = function
      | [] -> current_hash
      | hd :: tl ->
          let current_node_hash = current_hash + (n * hd) in

          current_node_hash + aux (n + 1) current_node_hash tl
    in

    aux 0 0 l
end

module IntSet = Set.Make(Int)

let generate_set_of_random_values ?(random_seed = None) maximal_value number_of_values =
  let result = ref IntSet.empty in

  let _ = match random_seed with
    | None -> Random.init (int_of_float (Unix.time ()))
    | Some seed -> Random.init seed
  in

  let _ =
    while IntSet.cardinal !result < number_of_values do
      let random_number = Random.int maximal_value in

      result := IntSet.add random_number !result
    done
  in

  !result

module StringSet = Set.Make(String)

module RandomTable = struct
  type 'a t = ('a, int) Hashtbl.t

  let make_empty_table () =
    Hashtbl.create 1

  let get_or_create_random_value element max table =
    let element_binding = Hashtbl.find_opt table element in

    match element_binding with
      | None ->
          let random_value = Random.int max in
          let _ = Hashtbl.add table element random_value in

          random_value
      | Some v -> v
end

module IntCouple = struct
  type t = int * int

  let equal (a1, b1) (a2, b2) =
    a1 == a2 && b1 == b2

  let hash (a, b) =
    a + (a * b)

  let compare a b =
    hash a - hash b
end

module IntCoupleSet = Set.Make(IntCouple)

module RandomStringGenerator = struct
  type generation_mode =
    | Unrestricted
    | Ascii_Only
    | Text_Only
    | Text_Only_With_Separator of int * char

  let generate_random_string ?(random_seed=None) ?(max_length=64) ?(generation_mode=Unrestricted) () =
    let length =
      match Random.int max_length with (* To prevent divisions by 0 *)
        | 0 -> 1
        | l -> l
    in

    let length_range = range length in

    let _ = match random_seed with
      | None -> Random.init (int_of_float (Unix.time ()))
      | Some seed -> Random.init seed
    in

    let text_only_generate_character_code () =
      (* 10 characters in [0-9] + 26 characters in [a-z] + 26 characters in [A-Z] = 62 characters *)
      let character_id = Random.int 63 in

      let character_opt = match character_id with
        | i when i < 10 -> Some (0x30 + i) (* 0x30: '0' *)
        | i when i >= 10 && i < 36 -> Some (0x41 + i - 10) (* 0x41: 'A' ; -10 to skip first [0-10] *)
        | i when i >= 36 && i < 62 -> Some (0x61 + i - 36) (* 0x61: 'a' ; -36 to skip first [0-10A-Z] *)
        | _ -> None
      in

      match character_opt with
        | Some char_id -> char_id
        | None -> 0x61 (* 'a' *)
    in

    List.fold_left (fun result i ->
      let character_int = match generation_mode with
        | Unrestricted -> Random.int 0xff
        | Ascii_Only -> (Random.int 95) + 32 (* 95 = 127 (DEL char) - 32 (SPACE char) *)
        | Text_Only ->
            text_only_generate_character_code ()
        | Text_Only_With_Separator (number_of_separators, separator) ->
            let substrings_length = length / (number_of_separators + 1) in
            let result_length = String.length result in

            if (substrings_length != 0) && (number_of_separators != 0) && (result_length != 0) && (i mod substrings_length) == 0 then
              Char.code separator
            else
              text_only_generate_character_code ()
      in

      let character = Char.chr character_int in

      let character_str = match character with
        | '[' -> "\\["
        | ']' -> "\\]"
        | _ -> (String.make 1 character)
      in

      result ^ character_str
    ) "" length_range
end

let fold_left_while f acc l =
  let rec aux acc continue l =
    match continue, l with
      | false, _ | _, [] -> (acc, continue)
      | true, hd :: tl ->
          let (new_acc, new_continue) = f acc hd in

          aux new_acc new_continue tl
  in

  let (result, _) = aux acc true l in

  result