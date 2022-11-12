@echo off
chcp 65001 >NUL 2>NUL

call "%~dp0\vsenv.cmd" 32

cd %~dp0

set cwd_step1=%~dp0
set cwd_final=%cwd_step1:\=/%
set lua_incdir=%cwd_final%include
set lua_libdir=%cwd_final%lib

luarocks.exe --tree "%cwd_final%" --lua-dir="%cwd_final%" LUA_DIR="%cwd_final%" LUA_INCDIR="%lua_incdir%" LUA_LIBDIR="%lua_libdir%" %*