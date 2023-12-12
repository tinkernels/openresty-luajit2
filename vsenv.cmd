@echo off
chcp 65001 >NUL 2>NUL

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
                echo Found MSBuild.exe CL.exe LINK.exe, will skip over visual studio env setting...
                goto ____skip_vsenv
        )
    )
)
echo=
echo setting visual studio env...
echo=

@REM    Determine path to VsDevCmd.bat
for /f "usebackq delims=#" %%a in (
    `"%programfiles(x86)%\Microsoft Visual Studio\Installer\vswhere" -latest -property installationPath`
) do set FOUND_VCVAR_BAT_PATH_BY_ME=%%a\VC\Auxiliary\Build

if [%1] equ [64] (
    call "%FOUND_VCVAR_BAT_PATH_BY_ME%\vcvars64.bat"
) else if [%1] equ [32] (
    call "%FOUND_VCVAR_BAT_PATH_BY_ME%\vcvars32.bat"
) else (
    call "%FOUND_VCVAR_BAT_PATH_BY_ME%\vcvarsall.bat" %*
)

set FOUND_VCVAR_BAT_PATH_BY_ME=

:____skip_vsenv
