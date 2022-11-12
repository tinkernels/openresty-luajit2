@echo off
chcp 65001 >NUL 2>NUL

set original_pwd=%CD%

cd %~dp0

echo=
echo where is MSBuild.exe...
where MSBuild.exe 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo=
    echo where is CL.exe...
    where CL.exe 2>&1
    IF %ERRORLEVEL% EQU 0 (
        echo=
        echo where is LINK.exe...
        where LINK.exe 2>&1
            IF %ERRORLEVEL% EQU 0 (
                echo=
                echo Found MSBuild CL LINK
                goto ____skip_vsenv
        )
    )
)
echo=
echo setting visual studio env...
echo=
call "%~dp0\vsenv.cmd" 32
:____skip_vsenv

set DIST_DIR=luajit-dist-win32
mkdir %DIST_DIR%\lib
mkdir %DIST_DIR%\include

cd luajit-src\src

call msvcbuild.bat

copy /Y /V *.exe ..\..\%DIST_DIR%
copy /Y /V *.dll ..\..\%DIST_DIR%
copy /Y /V "%~dp0vsenv.cmd" ..\..\%DIST_DIR%
copy /Y /V "%~dp0run-luarocks-win32.cmd" ..\..\%DIST_DIR%

copy /Y /V *.dll ..\..\%DIST_DIR%\lib
copy /Y /V *.lib ..\..\%DIST_DIR%\lib
copy /Y /V *.exp ..\..\%DIST_DIR%\lib

for %%x in (
        lua.h
        lauxlib.h
        lualib.h
        luajit.h
        luaconf.h
        lua.hpp
    ) do (
    copy /Y /V %%x ..\..\%DIST_DIR%\include
)
