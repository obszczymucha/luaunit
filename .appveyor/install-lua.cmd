REM This is a batch file to help with setting up the desired Lua environment.
REM It is intended to be run as "install" step from within AppVeyor.

REM version numbers and file names for binaries from http://sf.net/p/luabinaries/
set VER_51=5.1.5
set VER_52=5.2.4
set VER_53=5.3.3
set VER_54=5.4.0
set ZIP_51=lua-%VER_51%_Win32_bin.zip
set ZIP_52=lua-%VER_52%_Win32_bin.zip
set ZIP_53=lua-%VER_53%_Win32_bin.zip
set ZIP_54=lua-%VER_54%_Win32_bin.zip
set ZIP_LUAJIT20=LuaJIT-2.0.5
set ZIP_LUAJIT21=LuaJIT-2.1.0-beta3

goto %LUAENV%
goto error

:cinst
@echo off
echo Chocolatey install of Lua ...
if NOT EXIST "C:\Program Files (x86)\Lua\5.1\lua.exe" (
    @echo on
    cinst lua
) else (
    @echo on
    echo Using cached version of Lua
)
set LUA="C:\Program Files (x86)\Lua\5.1\lua.exe"
@echo off
goto :EOF

:lua51
set PRETTY_VERSION='Lua 5.1'
set LUADIR=lua51
set LUAEXE=lua51\lua5.1.exe
set DL_URL=http://sourceforge.net/projects/luabinaries/files/%VER_51%/Tools%%20Executables/%ZIP_51%/download
set DL_ZIP=%ZIP_51%
set LUAJIT=no
goto download_and_intall_lua

:lua52
set PRETTY_VERSION='Lua 5.2'
set LUADIR=lua52
set LUAEXE=lua52\lua5.2.exe
set DL_URL=http://sourceforge.net/projects/luabinaries/files/%VER_52%/Tools%%20Executables/%ZIP_52%/download
set DL_ZIP=%ZIP_52%
goto download_and_intall_lua

:lua53
set PRETTY_VERSION='Lua 5.3'
set LUADIR=lua53
set LUAEXE=lua53\lua5.3.exe
set DL_URL=http://sourceforge.net/projects/luabinaries/files/%VER_53%/Tools%%20Executables/%ZIP_53%/download
set DL_ZIP=%ZIP_53%
goto download_and_intall_lua

:lua54
set PRETTY_VERSION='Lua 5.4'
set LUADIR=lua54
set LUAEXE=lua54\lua5.4.exe
set DL_URL=http://sourceforge.net/projects/luabinaries/files/%VER_54%/Tools%%20Executables/%ZIP_54%/download
set DL_ZIP=%ZIP_54%
goto download_and_intall_lua


:luajit
@echo on
echo Setting up LuaJIT 2.0 ...
if NOT EXIST "luajit20\luajit.exe" (
    call %~dp0install-luajit.cmd LuaJIT-2.0.5 luajit20
) else (
    echo Using cached version of LuaJIT 2.0
)
set LUA=luajit20\luajit.exe
goto :EOF


:luajit21
@echo on
echo Setting up LuaJIT 2.1 ...
if NOT EXIST "luajit21\luajit.exe" (
    call %~dp0install-luajit.cmd LuaJIT-2.1.0-beta3 luajit21
) else (
    echo Using cached version of LuaJIT 2.1
)
set LUA=luajit21\luajit.exe
goto :EOF


:download_and_intall_lua
echo Setting up %PRETTY_VERSION% ...
if NOT EXIST %LUAEXE% (
    @echo on
    echo Fetching %PRETTY_VERSION% from internet
    curl -fLsS -o %DL_ZIP% %DL_URL%
    unzip -d %LUADIR% %DL_ZIP%
) else (
    echo Using cached version of %PRETTY_VERSION
)
set LUA=%LUAEXE%
goto :eof

:error
echo Do not know how to install %LUAENV%
