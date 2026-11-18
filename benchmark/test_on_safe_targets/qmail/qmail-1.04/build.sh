#!/bin/bash

export QMAIL_TAR=netqmail-1.04.tar.gz
export QMAIL_PATH=netqmail-1.04

tar xvf $QMAIL_TAR
cd $QMAIL_PATH

./collate.sh
cd $QMAIL_PATH

cat << EOF > conf-users
%USER
%USER
%USER
%USER
%USER
%USER
%USER
%USER

The qmail system is heavily partitioned for security; it does almost
nothing as root.

The first eight lines of this file are the alias user, the daemon user,
the log user, the owner of miscellaneous files such as binaries, the
passwd user, the queue user, the remote user, and the send user.
EOF

cat << EOF > conf-groups
%GROUP
%GROUP

These are the qmail groups. The second group should not have access to
any files, but it must be usable for processes; this requirement
excludes the ``nogroup'' and ``nobody'' groups on many systems.
EOF

USER=`id | tr " " "\n" | grep uid | cut -d"(" -f2 | cut -d")" -f1`
GROUP=`id | tr " " "\n" | grep gid | cut -d"(" -f2 | cut -d")" -f1`

sed -re "s/%USER/$USER/g" -i conf-users
sed -re "s/%GROUP/$GROUP/g" -i conf-groups

echo "\${CC} -g3 -std=gnu89 -O2" > ./conf-cc
echo "\${CC} -g3" > conf-ld

sed "171a  write(-1, \"__ROSAS_CANTINA__\", 17);" -i qmail-popup.c

make clean
CC=gcc make
cp qmail-popup qmail-popup.ori

make clean
rm -f qmail-popup.lto.afl
rm -f qmail-popup.lto.cmplog
rm -f qmail-popup.laf-intel.afl
CC=afl-clang-lto LD=afl-clang-lto make
cp qmail-popup qmail-popup.lto.afl
make clean
AFL_LLVM_CMPLOG=1 CC=afl-clang-lto LD=afl-clang-lto make
cp qmail-popup qmail-popup.lto.cmplog
make clean
AFL_LLVM_LAF_ALL=1 CC=afl-clang-fast LD=afl-clang-fast make
cp qmail-popup qmail-popup.laf-intel.afl

cd ../../
tar xvf ../Mailbox.tar.gz
