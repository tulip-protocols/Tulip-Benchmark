%{
    open Parser_types
    open Exceptions

    let parse_error s = raise (SyntaxError ("Syntax error in line " ^ (string_of_int !Parser_types.current_line)))

    let default_arg_separator = parser_arg_separator_definition_builder [' '] false
%}

%token EOF
%token CASE_SENSITIVITY
%token YES
%token NO
%token ARG_SEPARATOR
%token LEVEL
%token ARG
%token INITIAL_LEVEL
%token MULTIPLE
%token LEVELS
%token SYSCALL_MONITOR
%token ACCEPTED
%token REFUSED
%token OTHER_COMMANDS
%token IGNORED
%token ADVERSARIAL_SEQUENCES_GENERATION_MODE
%token FULL
%token MINIMAL
%token IMPORTANT
%token AUTHORIZED_SYSCALLS
%token IGNORE_EMPTY_COMMANDS
%token IGNORED_CHARS
%token COMMANDS_PREFIX
%token ADVERSARIAL_SEQUENCES_ENDING
%token SPLIT_ADVERSARIAL_SEQUENCES_ARGS
%token SYSCALLS_GETTING_MODE
%token PER_COMMANDS
%token ONE_SHOT
%token PER_COMMANDS_WITH_TIMEOUT
%token SEEDS
%token SYSCALLS_CHECKING_MODE
%token WITH_ANSWERS
%token WITHOUT_ANSWERS
%token EQUALS
%token SEMICOLON
%token PIPE
%token QUOTE
%token COLON
%token COMMA
%token DOUBLE_QUOTE
%token GREATER
%token LEFT_PARENTHESIS
%token RIGHT_PARENTHESIS
%token UNDERSCORE
%token <char> CHAR
%token <int> INT
%token <string> ID //Voir "lexer.mll"

%type <char> char
%type <char list> multiple_chars
%type <string> string
%type <string> string_with_spaces
%type <bool> case_sensitivity
%type <string> initial_level
%type <Parser_types.parser_arg_separator_definition> arg_separator
%type <bool> other_commands
%type <Parser_types.parser_adversarial_sequences_generation> adversarial_sequences_generation_mode
%type <bool> ignore_empty_commands
%type <char list> ignored_chars
%type <string> commands_prefix
%type <string> adversarial_sequences_ending
%type <bool> split_adversarial_sequences_args
%type <Parser_types.parser_syscalls_getting_mode> syscalls_getting_mode
%type <Parser_types.parser_syscalls_checking_mode> syscalls_checking_mode
%type <Parser_types.parser_arg_definition list> arg_definition_chain
%type <Parser_types.parser_command_definition list> command_definition_chain
%type <Parser_types.parser_level_definition list> level_definition_chain
%type <Parser_types.parser_level_definition list> levels
%type <string list> string_with_spaces_chain
%type <string list> refused_syscalls_patterns
%type <string list> ignored_syscalls_patterns
%type <string list> syscalls_names_chain
%type <Parser_types.parser_authorized_syscalls list> authorized_syscalls_commands_list
%type <Parser_types.parser_authorized_syscalls list> authorized_syscalls
%type <Parser_types.parser_syscalls_definition> syscall_monitor
%type <string list> per_command_seeds_commands_list
%type <string list> per_command_seeds_seeds_list
%type <Parser_types.parser_custom_seeds_definition list> per_command_seeds_chain
%type <Parser_types.parser_custom_seeds_definition list> seeds
%type <Parser_types.parser_csl_parameters_elements list> csl_parameters
%type <Parser_types.parser_csl> csl

%start csl
%%

char:
| QUOTE QUOTE { ' ' }
| QUOTE EQUALS QUOTE { '=' }
| QUOTE SEMICOLON QUOTE { ';' }
| QUOTE PIPE QUOTE { '|' }
| QUOTE COLON QUOTE { ':' }
| CHAR { $1 }
;

multiple_chars:
| char { [$1] }
| char PIPE multiple_chars { $1 :: $3 }
;

string:
| ID { $1 }
;

string_with_spaces:
| ID { $1 }
| ID string_with_spaces { $1 ^ " " ^ $2 }
;

case_sensitivity:
| CASE_SENSITIVITY EQUALS YES SEMICOLON { true }
| CASE_SENSITIVITY EQUALS NO SEMICOLON { false }
;

initial_level:
| INITIAL_LEVEL EQUALS string SEMICOLON { $3 }
;

arg_separator:
| ARG_SEPARATOR EQUALS multiple_chars SEMICOLON { parser_arg_separator_definition_builder $3 false }
| ARG_SEPARATOR EQUALS multiple_chars MULTIPLE SEMICOLON { parser_arg_separator_definition_builder $3 true }
;

other_commands:
| OTHER_COMMANDS EQUALS YES SEMICOLON { true }
| OTHER_COMMANDS EQUALS NO SEMICOLON { false }
;

adversarial_sequences_generation_mode:
| ADVERSARIAL_SEQUENCES_GENERATION_MODE EQUALS FULL SEMICOLON { Full }
| ADVERSARIAL_SEQUENCES_GENERATION_MODE EQUALS MINIMAL SEMICOLON { Minimal }
;

ignore_empty_commands:
| IGNORE_EMPTY_COMMANDS EQUALS YES SEMICOLON { true }
| IGNORE_EMPTY_COMMANDS EQUALS NO SEMICOLON { false }
;

ignored_chars:
| IGNORED_CHARS EQUALS multiple_chars SEMICOLON { $3 }
;

commands_prefix:
| COMMANDS_PREFIX EQUALS string SEMICOLON { $3 }
;

adversarial_sequences_ending:
| ADVERSARIAL_SEQUENCES_ENDING EQUALS string SEMICOLON { $3 }
;

split_adversarial_sequences_args:
| SPLIT_ADVERSARIAL_SEQUENCES_ARGS EQUALS YES SEMICOLON { true }
| SPLIT_ADVERSARIAL_SEQUENCES_ARGS EQUALS NO SEMICOLON { false }
;

syscalls_getting_mode:
| SYSCALLS_GETTING_MODE EQUALS PER_COMMANDS SEMICOLON { Per_Commands }
| SYSCALLS_GETTING_MODE EQUALS ONE_SHOT SEMICOLON { One_Shot }
| SYSCALLS_GETTING_MODE EQUALS PER_COMMANDS_WITH_TIMEOUT SEMICOLON { Per_Commands_With_Timeout }
;

syscalls_checking_mode:
| SYSCALLS_CHECKING_MODE EQUALS WITH_ANSWERS SEMICOLON { With_Answers }
| SYSCALLS_CHECKING_MODE EQUALS WITHOUT_ANSWERS SEMICOLON { Without_Answers }
;

arg_definition_chain:
| UNDERSCORE { [parser_arg_definition_builder "_" "" false ] }
| UNDERSCORE IMPORTANT { [parser_arg_definition_builder "_" "" true ] }
| UNDERSCORE EQUALS GREATER LEVEL EQUALS string { [parser_arg_definition_builder "_" $6 false ] }
| UNDERSCORE EQUALS GREATER LEVEL EQUALS string IMPORTANT { [parser_arg_definition_builder "_" $6 true ] }
| ARG EQUALS EQUALS string { [parser_arg_definition_builder $4 "" false ] }
| ARG EQUALS EQUALS string IMPORTANT { [parser_arg_definition_builder $4 "" true ] }
| ARG EQUALS EQUALS string PIPE arg_definition_chain { List.append [parser_arg_definition_builder $4 "" false ] $6 }
| ARG EQUALS EQUALS string IMPORTANT PIPE arg_definition_chain { List.append [parser_arg_definition_builder $4 "" true ] $7 }
| ARG EQUALS EQUALS string EQUALS GREATER LEVEL EQUALS string { [parser_arg_definition_builder $4 $9 false ] }
| ARG EQUALS EQUALS string EQUALS GREATER LEVEL EQUALS string IMPORTANT { [parser_arg_definition_builder $4 $9 true ] }
| ARG EQUALS EQUALS string EQUALS GREATER LEVEL EQUALS string PIPE arg_definition_chain { List.append [parser_arg_definition_builder $4 $9 false ] $11 }
| ARG EQUALS EQUALS string EQUALS GREATER LEVEL EQUALS string IMPORTANT PIPE arg_definition_chain { List.append [parser_arg_definition_builder $4 $9 true ] $12 }
;

command_definition_chain:
| string_with_spaces { [parser_command_definition_builder $1 [] None] }
| string_with_spaces LEFT_PARENTHESIS arg_definition_chain RIGHT_PARENTHESIS { [parser_command_definition_builder $1 $3 None] }
| string_with_spaces LEFT_PARENTHESIS arg_definition_chain RIGHT_PARENTHESIS string_with_spaces { [parser_command_definition_builder $1 $3 (Some $5) ] }
| string_with_spaces LEFT_PARENTHESIS arg_definition_chain RIGHT_PARENTHESIS COMMA command_definition_chain { List.append [parser_command_definition_builder $1 $3 None] $6 }
| string_with_spaces LEFT_PARENTHESIS arg_definition_chain RIGHT_PARENTHESIS string_with_spaces COMMA command_definition_chain { List.append [parser_command_definition_builder $1 $3 (Some $5)] $7 }
| string_with_spaces COMMA command_definition_chain { List.append [parser_command_definition_builder $1 [] None] $3 }
;

level_definition_chain:
| LEVEL string COLON command_definition_chain SEMICOLON { [parser_level_definition_builder $2 $4] }
| LEVEL string COLON command_definition_chain SEMICOLON level_definition_chain { List.append [parser_level_definition_builder $2 $4] $6 }
;

levels:
| LEVELS COLON level_definition_chain { $3 }
;

syscall_arg_chain:
| INT { [Int.to_string $1] }
| char { [Char.escaped $1] }
| string { [$1] }
| INT COMMA syscall_arg_chain { List.rev_append [Int.to_string $1] $3 }
| char COMMA syscall_arg_chain { List.rev_append [Char.escaped $1] $3 }
| string COMMA syscall_arg_chain { List.rev_append [$1] $3 }
;

string_with_spaces_chain:
| string { [$1] }
| string COMMA string_with_spaces_chain { $1 :: $3 }
;

refused_syscalls_patterns:
| REFUSED COLON string_with_spaces_chain SEMICOLON { $3 }
;

ignored_syscalls_patterns:
| IGNORED COLON string_with_spaces_chain SEMICOLON { $3 }
;

syscalls_names_chain:
| { [] }
| ID { [$1] }
| ID COMMA syscalls_names_chain { $1 :: $3 }
;

authorized_syscalls_commands_list:
| ID LEFT_PARENTHESIS syscalls_names_chain RIGHT_PARENTHESIS { [parser_authorized_syscalls_builder $1 $3] }
| OTHER_COMMANDS LEFT_PARENTHESIS syscalls_names_chain RIGHT_PARENTHESIS { [parser_authorized_syscalls_builder "other_commands" $3] }
| ID LEFT_PARENTHESIS syscalls_names_chain RIGHT_PARENTHESIS COMMA authorized_syscalls_commands_list { (parser_authorized_syscalls_builder $1 $3) :: $6 }
| OTHER_COMMANDS LEFT_PARENTHESIS syscalls_names_chain RIGHT_PARENTHESIS COMMA authorized_syscalls_commands_list { (parser_authorized_syscalls_builder "other_commands" $3) :: $6 }
;

authorized_syscalls:
| AUTHORIZED_SYSCALLS COLON authorized_syscalls_commands_list SEMICOLON { $3 }
;

syscall_monitor:
| SYSCALL_MONITOR COLON refused_syscalls_patterns { parser_syscalls_definition_builder $3 [] [] }
| SYSCALL_MONITOR COLON refused_syscalls_patterns authorized_syscalls { parser_syscalls_definition_builder $3 [] $4 }
| SYSCALL_MONITOR COLON refused_syscalls_patterns ignored_syscalls_patterns { parser_syscalls_definition_builder $3 $4 [] }
| SYSCALL_MONITOR COLON refused_syscalls_patterns ignored_syscalls_patterns authorized_syscalls { parser_syscalls_definition_builder $3 $4 $5 }
;

per_command_seeds_commands_list:
| ID { [$1] }
| ID COMMA per_command_seeds_commands_list { $1 :: $3 }
;

per_command_seeds_seeds_list:
| string_with_spaces { [$1] }
| string_with_spaces COMMA per_command_seeds_seeds_list { $1 :: $3 }
;

per_command_seeds_chain:
| per_command_seeds_commands_list COLON per_command_seeds_seeds_list SEMICOLON { [parser_custom_seeds_definition_builder $1 $3] }
| per_command_seeds_commands_list COLON per_command_seeds_seeds_list SEMICOLON per_command_seeds_chain { parser_custom_seeds_definition_builder $1 $3 :: $5 }
;

seeds:
| SEEDS COLON per_command_seeds_chain { $3 }
;

csl_parameters:
| { [] }
| case_sensitivity csl_parameters { Case_Sensitivity $1 :: $2 }
| arg_separator csl_parameters { Arg_Separator $1 :: $2 }
| initial_level csl_parameters { Initial_Level $1 :: $2 }
| other_commands csl_parameters { Consider_Other_Commands $1 :: $2 }
| adversarial_sequences_generation_mode csl_parameters { Adversarial_Sequences_Generation $1 :: $2 }
| ignore_empty_commands csl_parameters { Ignore_Empty_Commands $1 :: $2 }
| ignored_chars csl_parameters { Ignored_Chars $1 :: $2 }
| commands_prefix csl_parameters { Commands_Prefix $1 :: $2 }
| adversarial_sequences_ending csl_parameters { Adversarial_Sequences_Ending $1 :: $2 }
| split_adversarial_sequences_args csl_parameters { Split_Adversarial_Sequences_Args $1 :: $2 }
| syscalls_getting_mode csl_parameters { Syscalls_Getting_Mode $1 :: $2 }
| syscalls_checking_mode csl_parameters { Syscalls_Checking_Mode $1 :: $2 }
;

csl:
| csl_parameters levels { parser_csl_builder $1 $2 None None }
| csl_parameters levels syscall_monitor { parser_csl_builder $1 $2 (Some $3) None }
| csl_parameters levels seeds { parser_csl_builder $1 $2 None (Some $3) }
| csl_parameters levels syscall_monitor seeds { parser_csl_builder $1 $2 (Some $3) (Some $4) }
;