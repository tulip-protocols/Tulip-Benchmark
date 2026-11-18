#!/bin/bash

cp ../vsftpd.conf .
sed -re "s/^seccomp_sandbox.*$//g" -i vsftpd.conf

tar xvf ../vsftpd.git.tar
git config --global --add safe.directory $PWD/vsftpd.git
git clone vsftpd.git
cd vsftpd
git checkout 2.0.7

# Adds -lcap and -lpam to the link stage
patch_makefile()
{
    COMPILER=$1

    sed -re '9s/$/ -lcap -lpam/g' -i Makefile

    if [ "x$COMPILER" != "x" ]
    then
        sed -re "2s/gcc/$COMPILER/g" -i Makefile
    fi
}

add_rosa_marker()
{
    patch -p1 < ../main.c-rosa.patch
}

git restore .
git clean -fx .
add_rosa_marker
patch_makefile
make
cp vsftpd ../vsftpd.ori

git restore .
git clean -fx .
add_rosa_marker
patch_makefile afl-clang-lto
make
cp vsftpd ../vsftpd.lto.afl

git restore .
git clean -fx .
add_rosa_marker
patch_makefile afl-clang-lto
AFL_LLVM_CMPLOG=1 make
cp vsftpd ../vsftpd.lto.cmplog

git restore .
git clean -fx .
add_rosa_marker
patch_makefile afl-clang-fast
AFL_LLVM_LAF_ALL=1 make
cp vsftpd ../vsftpd.laf-intel.afl
