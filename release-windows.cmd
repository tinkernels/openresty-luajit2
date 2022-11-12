@echo off
chcp 65001 >NUL 2>NUL

set original_pwd=%CD%

cd %~dp0

git clone --depth 1 --recurse-submodules --branch v2.1-agentzh https://github.com/openresty/luajit2.git luajit-src

cmd /c release-win32.cmd
cmd /c release-winx64.cmd

7z a luajit-dist-winx64.7z luajit-dist-winx64
7z a luajit-dist-win32.7z luajit-dist-win32