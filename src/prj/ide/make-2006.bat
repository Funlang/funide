@echo off
rem ============================================================
rem Build funide.exe with Delphi 2006 (Win32, ANSI)
rem ============================================================
rem Mirrors fun/src/prj/fun/make-2006.bat: set up the toolchain
rem from setenv.bat, merge the IDE sources into the Fun checkout,
rem then run dcc32 on funide.dpr.
rem
rem Extra dcc32 switches can be appended, e.g. `make-2006.bat -B`.
rem ============================================================

call "%~dp0setenv.bat"
call "%~dp0sync-ide.bat" || exit /b 1

set "DCC=%DELPHI2006%\bin\dcc32"
set "PRJ=%FUN_ROOT%\src\prj\ide"
set "OUTDIR=%FUN_ROOT%\fun"

set "UNITPATH=%FUN_ROOT%\src\core;%FUN_ROOT%\src\lib;%FUN_ROOT%\src\lib\ui;%FUN_ROOT%\src\parse;%FUN_ROOT%\src\regex;%FUN_ROOT%\src\regex\pcre;%FUN_ROOT%\src\utils;%FUN_ROOT%\src\3rd;%FUN_ROOT%\src\ide;%FUN_ROOT%\src\prj\ide;%SYNCEDIT%;%VST%"
set "INCPATH=%SYNCEDIT%;%FUN_ROOT%\src\ide;%FUN_ROOT%\src\prj\ide"

echo [funide] building with "%DCC%"
pushd "%PRJ%"
"%DCC%" funide -B -Q -GD -$D+ -D_B_;_C_;CalcOpt;WinAPI;WinCOM;Regex;FunUI;MD5;IDE;xUNICODE_CTRLS;NewHintX -U"%UNITPATH%" -I"%INCPATH%" -E"%OUTDIR%" %*
set "RC=%ERRORLEVEL%"
popd
if not "%RC%"=="0" echo [funide] build failed with exit code %RC%
exit /b %RC%
