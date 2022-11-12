#!/usr/bin/env bash

# shellcheck disable=SC2296
# ---------------- GET SELF PATH ----------------
ORIGINAL_PWD_GETSELFPATHVAR=$(pwd)
if test -n "$BASH"; then SH_FILE_RUN_PATH_GETSELFPATHVAR=${BASH_SOURCE[0]}
elif test -n "$ZSH_NAME"; then SH_FILE_RUN_PATH_GETSELFPATHVAR=${(%):-%x}
elif test -n "$KSH_VERSION"; then SH_FILE_RUN_PATH_GETSELFPATHVAR=${.sh.file}
else SH_FILE_RUN_PATH_GETSELFPATHVAR=$(lsof -p $$ -Fn0 | tr -d '\0' | grep "${0##*/}" | tail -1 | sed 's/^[^\/]*//g')
fi
cd "$(dirname "$SH_FILE_RUN_PATH_GETSELFPATHVAR")" || return 1
SH_FILE_RUN_BASENAME_GETSELFPATHVAR=$(basename "$SH_FILE_RUN_PATH_GETSELFPATHVAR")
while [ -L "$SH_FILE_RUN_BASENAME_GETSELFPATHVAR" ]; do
    SH_FILE_REAL_PATH_GETSELFPATHVAR=$(readlink "$SH_FILE_RUN_BASENAME_GETSELFPATHVAR")
    cd "$(dirname "$SH_FILE_REAL_PATH_GETSELFPATHVAR")" || return 1
    SH_FILE_RUN_BASENAME_GETSELFPATHVAR=$(basename "$SH_FILE_REAL_PATH_GETSELFPATHVAR")
done
SH_SELF_PATH_DIR_RESULT=$(pwd -P)
SH_FILE_REAL_PATH_GETSELFPATHVAR=$SH_SELF_PATH_DIR_RESULT/$SH_FILE_RUN_BASENAME_GETSELFPATHVAR
cd "$ORIGINAL_PWD_GETSELFPATHVAR" || return 1
unset ORIGINAL_PWD_GETSELFPATHVAR SH_FILE_RUN_PATH_GETSELFPATHVAR SH_FILE_RUN_BASENAME_GETSELFPATHVAR SH_FILE_REAL_PATH_GETSELFPATHVAR
# ---------------- GET SELF PATH ----------------
# USE $SH_SELF_PATH_DIR_RESULT BEBLOW

cd "$SH_SELF_PATH_DIR_RESULT" || exit

brew update; brew upgrade

git clone --depth 1 --recurse-submodules --branch v2.1-agentzh https://github.com/openresty/luajit2.git luajit-src

mkdir ./luajit-dist

cd luajit-dist || exit
TK_CUSTOM_LUA_PREFIX_DIR=$(pwd -P)
echo "TK_CUSTOM_LUA_PREFIX_DIR: $TK_CUSTOM_LUA_PREFIX_DIR"

cd "$SH_SELF_PATH_DIR_RESULT/luajit-src" || exit

MACOSX_DEPLOYMENT_TARGET=10.10 make clean

MACOSX_DEPLOYMENT_TARGET=10.10 make PREFIX=luajit-dist

MACOSX_DEPLOYMENT_TARGET=10.10 make install PREFIX="$TK_CUSTOM_LUA_PREFIX_DIR"

cd "$SH_SELF_PATH_DIR_RESULT" || exit

echo "checking luajit."
luajit-dist/bin/luajit -v

echo "will pack release files."

TK_LUAJIT_RELEASE_TARBALL="luajit-dist-macos-amd64.tar.gz"

tar -cvf "$TK_LUAJIT_RELEASE_TARBALL" luajit-dist
