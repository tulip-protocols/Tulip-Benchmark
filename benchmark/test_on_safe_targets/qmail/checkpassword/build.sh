#!/bin/bash -e

export CC=gcc

tar xvf checkpassword-0.90.tar.gz
cd checkpassword-0.90

cat << EOF > ./conf-cc
${CC} -g3 -std=gnu89 -O2


This will be used to compile .c files.
EOF

echo "\${CC} -g3" > ./conf-ld

patch ./Makefile < ../checkpassword-Makefile.patch
patch ./error.h < ../checkpassword-error-h.patch

make clean
make
