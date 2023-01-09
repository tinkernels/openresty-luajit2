#!/usr/bin/env bash

# shellcheck disable=SC2296
# ---------------- GET SELF PATH ----------------
ORIGINAL_PWD_GETSELFPATHVAR=$(pwd) ; if test -n "$BASH"; then SH_FILE_RUN_PATH_GETSELFPATHVAR=${BASH_SOURCE[0]}; elif test -n "$ZSH_NAME"; then SH_FILE_RUN_PATH_GETSELFPATHVAR=${(%):-%x} ; elif test -n "$KSH_VERSION"; then SH_FILE_RUN_PATH_GETSELFPATHVAR=${.sh.file} ; else SH_FILE_RUN_PATH_GETSELFPATHVAR=$(lsof -p $$ -Fn0 | tr -d '\0' | grep "${0##*/}" | tail -1 | sed 's/^[^\/]*//g') ; fi; cd "$(dirname "$SH_FILE_RUN_PATH_GETSELFPATHVAR")" || return 1 ; SH_FILE_RUN_BASENAME_GETSELFPATHVAR=$(basename "$SH_FILE_RUN_PATH_GETSELFPATHVAR") ; while [ -L "$SH_FILE_RUN_BASENAME_GETSELFPATHVAR" ]; do SH_FILE_REAL_PATH_GETSELFPATHVAR=$(readlink "$SH_FILE_RUN_BASENAME_GETSELFPATHVAR"); cd "$(dirname "$SH_FILE_REAL_PATH_GETSELFPATHVAR")" || return 1 ; SH_FILE_RUN_BASENAME_GETSELFPATHVAR=$(basename "$SH_FILE_REAL_PATH_GETSELFPATHVAR"); done; SH_SELF_PATH_DIR_RESULT=$(pwd -P) ; SH_FILE_REAL_PATH_GETSELFPATHVAR=$SH_SELF_PATH_DIR_RESULT/$SH_FILE_RUN_BASENAME_GETSELFPATHVAR ; cd "$ORIGINAL_PWD_GETSELFPATHVAR" || return 1 ; unset ORIGINAL_PWD_GETSELFPATHVAR SH_FILE_RUN_PATH_GETSELFPATHVAR SH_FILE_RUN_BASENAME_GETSELFPATHVAR SH_FILE_REAL_PATH_GETSELFPATHVAR
# ---------------- GET SELF PATH ----------------
# USE $SH_SELF_PATH_DIR_RESULT BEBLOW

cd "$SH_SELF_PATH_DIR_RESULT" || exit

# Originally for cirrus ci, build only when recent tag exists.
GIT_MOST_RECENT_TAG=$(git describe --tags --abbrev=0 "$(git rev-list --tags --max-count=1)")
if [ -n "$GIT_MOST_RECENT_TAG" ];then
    echo "GIT_MOST_RECENT_TAG: $GIT_MOST_RECENT_TAG"
else
    echo "No tag found, skip job." && exit
fi

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

echo "changing dylib id."
install_name_tool -id @rpath/libluajit-5.1.dylib luajit-dist/lib/libluajit-5.1.dylib

cp -fv "$SH_SELF_PATH_DIR_RESULT/run-luarocks.sh" "$TK_CUSTOM_LUA_PREFIX_DIR"

echo "will pack release files."

TK_LUAJIT_RELEASE_TARBALL="luajit-dist-macos-arm64.tar.gz"

tar -cvf "$TK_LUAJIT_RELEASE_TARBALL" luajit-dist

# Upload release artificats to github release assets
FILES_TO_UPLOAD=(
  "$TK_LUAJIT_RELEASE_TARBALL"
)

if [[ "$GITHUB_TOKEN" == "" ]]; then
  echo "Please provide GitHub access token via GITHUB_TOKEN environment variable!"
  exit 1
fi

FILE_CONTENT_TYPE="application/octet-stream"

function get_release_id_of_git_tag {
    JSON_GITHUB_RELEASES_=$(curl -sSfL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$CIRRUS_REPO_FULL_NAME/releases")

    [ -n "$JSON_GITHUB_RELEASES_" ] || exit

    PY_CODE_=$(cat <<EOF
import json
import sys
try:
    j_ = json.load(sys.stdin)
    for release_ in j_:
        if release_["tag_name"] == "$1":
            print(release_["id"])
except (Exception,):
    pass
EOF
)
    echo "$JSON_GITHUB_RELEASES_" | python3 -c "$PY_CODE_"
}

# Loop until github release for current 
GITHUB_RELEASE_ID_=""
while true
do
    GITHUB_RELEASE_ID_=$(get_release_id_of_git_tag "$GIT_MOST_RECENT_TAG")
    [ -n "$GITHUB_RELEASE_ID_" ] && break
    sleep 60
done

for FPATH in "${FILES_TO_UPLOAD[@]}"
do
    echo "Uploading $FPATH..."
    NAME=$(basename "$FPATH")
    URL_TO_UPLOAD="https://uploads.github.com/repos/$CIRRUS_REPO_FULL_NAME/releases/$GITHUB_RELEASE_ID_/assets?name=$NAME"
    curl -X POST \
        --data-binary @"$FPATH" \
        --header "Authorization: token $GITHUB_TOKEN" \
        --header "Content-Type: $FILE_CONTENT_TYPE" \
        "$URL_TO_UPLOAD"
done
