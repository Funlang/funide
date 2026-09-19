@echo off
rem ============================================================
rem Copy funide's IDE sources into the Fun checkout
rem ============================================================
rem funide.dpr and ide.pas address the Fun language sources
rem through relative paths that only resolve once the IDE layer
rem sits inside the `fun` source tree, e.g.:
rem
rem   funide/src/prj/ide/funide.dpr:
rem     ide        in '..\..\ide\ide.pas'         ->  fun/src/ide/ide.pas
rem     pcrd, pcre in '..\..\regex\pcre\*.pas'     ->  fun/src/regex/pcre/*.pas
rem   funide/src/ide/ide.pas:
rem     uses fun, base, core, host, parse, pcre, ui, io
rem                                                ->  found on the compiler
rem                                                    unit search path (-U),
rem                                                    which the make-*.bat
rem                                                    scripts fill from FUN_ROOT
rem
rem This script mirrors the funide/src subtree into FUN_ROOT/src:
rem
rem   funide/src/ide      ->  %FUN_ROOT%\src\ide
rem   funide/src/prj/ide  ->  %FUN_ROOT%\src\prj\ide
rem
rem It is idempotent and safe to re-run. The copied files show up
rem as untracked files in the `fun` checkout; that is expected.
rem ============================================================

call "%~dp0setenv.bat"

rem --- If we are already building inside the Fun tree, do nothing. ---
if /I "%FUN_ROOT%\src\prj\ide\"=="%~dp0" (
  echo [funide] already building inside FUN_ROOT, skipping copy.
  exit /b 0
)

if not exist "%FUN_ROOT%\src\core\fun.pas" (
  echo [funide] FUN_ROOT does not look like a Fun checkout: "%FUN_ROOT%"
  echo [funide] set FUN_ROOT to the folder that contains src\core\fun.pas.
  exit /b 1
)

echo [funide] syncing IDE sources into "%FUN_ROOT%\src"
xcopy "%~dp0..\..\ide" "%FUN_ROOT%\src\ide\"     /E /I /Y >nul
xcopy "%~dp0"          "%FUN_ROOT%\src\prj\ide\" /E /I /Y >nul
if errorlevel 1 (
  echo [funide] copy failed.
  exit /b 1
)
exit /b 0
