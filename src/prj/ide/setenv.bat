@echo off
rem ============================================================
rem Fun IDE (funide) build environment
rem ============================================================
rem funide does NOT carry the Fun language implementation. The
rem interpreter (core, parse, lib, regex) is compiled from the
rem neighbouring `fun` project, so point FUN_ROOT at that
rem checkout before building.
rem
rem Edit the paths below to match your machine, then run any of
rem the make-*.bat scripts in this folder.
rem
rem You may also pre-set these variables in your shell/IDE before
rem running a build; the `if not defined` guards let your values
rem win. This mirrors fun/src/prj/fun/setenv.bat in the `fun`
rem project.
rem ============================================================

rem --- Fun language checkout (the sibling `fun` repository) ---
rem     Must contain src\core\fun.pas, src\parse, src\lib, src\regex.
rem     Default assumes funide and fun are checked out side by side:
rem         <parent>\funide\src\prj\ide\  ->  <parent>\fun\
if not defined FUN_ROOT set FUN_ROOT=%~dp0..\..\..\..\fun
for %%I in ("%FUN_ROOT%") do set "FUN_ROOT=%%~fI"

rem --- Delphi compilers (used by make-2006.bat / make-2009.bat) ---
if not defined DELPHI2006 set DELPHI2006=D:\Borland\Delphi2006
if not defined DELPHI2009 set DELPHI2009=D:\Borland\Delphi2009

rem --- Third-party VCL components the IDE links against ---
rem     SynEdit:        the folder that holds SynEdit.inc and the *.pas sources
rem     VirtualTrees:   the folder that holds VirtualTrees.pas
if not defined SYNCEDIT set SYNCEDIT=D:\Delphi\SynEdit\Source
if not defined VST      set VST=D:\Delphi\VirtualTreeviewV5.5.3\Source
