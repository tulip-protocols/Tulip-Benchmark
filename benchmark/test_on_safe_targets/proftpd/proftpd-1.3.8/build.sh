#!/bin/bash

tar xvf ../proftpd.git.tar
git config --global --add safe.directory $PWD/proftpd.git
git clone proftpd.git
cd proftpd
git checkout v1.3.8

# Problematic commit: dae4cad8acce37174ad9f3cbcb30fa89439816e0
# In the file configure, line 15608, LDFLAGS="$LDFLAGS -rdynamic" sets "-rdynamic",
# exporting the symbols table of the binary, and preventing patching
# functions via LD_PRELOAD (Required for fuzzing)
patch_configure()
{
    RDYNAMIC_LDFLAGS_LINE=`grep -n -- "LDFLAGS=.*rdynamic" configure | cut -d':' -f1`

    sed -re "${RDYNAMIC_LDFLAGS_LINE}s/^.*$/true/g" -i configure
}

add_rosa_marker()
{
    patch -p1 < ../main.c-rosa.patch
}

# Vanilla version build
git clean -fx .
git restore .
patch_configure
add_rosa_marker
./configure
make
cp ./proftpd ../proftpd.ori

# AFL++ LTO version build
git clean -fx .
git restore .
patch_configure
add_rosa_marker
CC=afl-clang-lto LD=afl-clang-lto ./configure
CC=afl-clang-lto LD=afl-clang-lto make
cp ./proftpd ../proftpd.lto.afl

# AFL++ LTO/cmplog version build
git clean -fx .
git restore .
patch_configure
add_rosa_marker
CC=afl-clang-lto LD=afl-clang-lto ./configure
AFL_LLVM_CMPLOG=1 CC=afl-clang-lto LD=afl-clang-lto make
cp ./proftpd ../proftpd.lto.cmplog

# AFL++ LAF-Intel version build
git clean -fx .
git restore .
patch_configure
add_rosa_marker
CC=afl-clang-fast LD=afl-clang-fast ./configure
AFL_LLVM_LAF_ALL=1 CC=afl-clang-fast LD=afl-clang-fast make
cp ./proftpd ../proftpd.laf-intel.afl