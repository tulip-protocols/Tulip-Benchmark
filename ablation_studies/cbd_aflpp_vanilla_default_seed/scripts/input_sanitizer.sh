#!/bin/bash

INPUT="$1"
OUTPUT="$2"

cat "$INPUT" | tr "\0" "\n" > "$OUTPUT"