# Funide

The **funide** IDE and editor tooling for the
[Fun](https://funlang.org) programming language.

**English** (this file) · [简体中文](README.zh.md)

- Website: <https://funlang.org>
- License: MIT (see [LICENSE](LICENSE))

This repository holds only the IDE layer: the Delphi/VCL desktop editor and
the Fun TextMate grammar. The Fun language itself (interpreter, parser, runtime
library, regex) is **not** duplicated here; it is compiled from the neighbouring
[`fun`](https://github.com/Funlang/fun) project, which is released separately.

---

## Contents

- [`src/ide/`](src/ide) — the IDE units: the main window (`ide.pas`/`ide.dfm`),
  the Fun/Regex/FD syntax highlighters (`funsyntax.pas`, `regexsyntax.pas`,
  `fdsyntax.pas`), the debugger glue (`debug.pas`), and resources.
- [`src/prj/ide/`](src/prj/ide) — the Delphi project (`funide.dpr`,
  `funide.res`) and the Windows build scripts.
- [`syntaxes/fun.tmLanguage.yaml`](syntaxes/fun.tmLanguage.yaml) — the Fun
  [TextMate](https://macromates.com/manual/en/language_grammars) grammar
  (`scopeName: source.fun`) used for syntax highlighting. It is derived from
  the Fun implementation's lexer (`src/parse/bnf/lex.l`), grammar
  (`src/parse/bnf/yacc.y`) and keyword table (`src/parse/id.inc`).

---

## Repository layout

```text
funide/
├── src/
│   ├── ide/                  # IDE units (funide.exe)
│   └── prj/ide/              # funide.dpr + Windows build scripts
└── syntaxes/
    └── fun.tmLanguage.yaml   # Fun TextMate grammar
```

---

## Relationship to the `fun` project

funide does not contain a copy of the Fun language. `funide.dpr` and `ide.pas`
link directly against the `fun` sources:

- `funide.dpr` references the Fun regex engine with relative unit paths:

  ```pascal
  ide  in '..\..\ide\ide.pas'          // this repository
  pcrd in '..\..\regex\pcre\pcrd.pas'  // the `fun` project
  pcre in '..\..\regex\pcre\pcre.pas'  // the `fun` project
  ```

- `ide.pas` and `debug.pas` use the Fun units by name:

  ```pascal
  uses fun, base, core, host, parse, pcre, ui, io;
  ```

Those relative paths and unit names resolve only when the IDE layer sits
**inside the `fun` source tree**. The build scripts therefore merge this
repository's `src/ide` and `src/prj/ide` into the `fun` checkout before
compiling:

```text
funide/src/ide      ->  <FUN_ROOT>\src\ide
funide/src/prj/ide  ->  <FUN_ROOT>\src\prj\ide
```

The Fun units (`src/core`, `src/lib`, `src/parse`, `src/regex`, `src/3rd`,
`src/utils`) come from `<FUN_ROOT>` unchanged; the compiler unit search path
(`-U`) is filled from it. This keeps the Fun implementation in exactly one
place while the IDE stays in this repository.

Thus, at build time, the tree looks like:

```text
<FUN_ROOT>/                          # a checked-out `fun` project
├── src/
│   ├── core/  lib/  lib/ui/  parse/  regex/  regex/pcre/  utils/  3rd/   # from `fun`
│   ├── ide/                          # copied from funide/src/ide
│   └── prj/
│       ├── fun/                      # from `fun`
│       └── ide/                      # copied from funide/src/prj/ide
└── fun/                              # distribution folder; funide.exe is written here
```

The copied files appear as untracked files in the `fun` checkout. That is
expected; the IDE sources are maintained here, not there.

---

## Building

`funide.exe` is a 32-bit Windows VCL application built with Delphi.

### Prerequisites

| Item | Notes |
| ---- | ----- |
| A `fun` checkout | The language sources funide compiles against. Set `FUN_ROOT` to it. |
| Delphi 2006 or 2009 | `DELPHI2006` / `DELPHI2009` are used by `make-2006.bat` / `make-2009.bat`. The 2006 build is ANSI; the 2009 build is Unicode. |
| [SynEdit](https://github.com/SynEdit/SynEdit) | The editor component. Point `SYNCEDIT` at the folder containing `SynEdit.inc` and the `SynEdit*.pas` sources. |
| [VirtualTrees](https://github.com/Virtual-TreeView/Virtual-TreeView) | The tree view component. Point `VST` at the folder containing `VirtualTrees.pas`. |
| PCRE 8 (8-bit) | Required for the Fun regex engine. Build it as described in the `fun` project's `README` (`src/regex/pcre/make.bat`). |

SynEdit and VirtualTrees are third-party components and are not vendored here.

### Toolchain configuration

All machine-specific paths live in one file,
[`src/prj/ide/setenv.bat`](src/prj/ide/setenv.bat), which mirrors
`fun/src/prj/fun/setenv.bat`. Edit it once, or pre-set the variables in your
shell:

| Variable | Meaning | Default |
| -------- | ------- | ------- |
| `FUN_ROOT` | Root of the `fun` checkout | `..\..\..\..\fun` (a sibling of this repository) |
| `DELPHI2006` | Delphi 2006 install root | `D:\Borland\Delphi2006` |
| `DELPHI2009` | Delphi 2009 install root | `D:\Borland\Delphi2009` |
| `SYNCEDIT` | SynEdit source folder | `D:\Delphi\SynEdit\Source` |
| `VST` | VirtualTrees source folder | `D:\Delphi\VirtualTreeviewV5.5.3\Source` |

Every `if not defined` guard lets a value you set beforehand win.

### Build steps

```text
cd src\prj\ide
make-2009.bat            # or: make-2006.bat
```

`make-2009.bat`:

1. loads the toolchain from `setenv.bat`;
2. runs `sync-ide.bat` to copy `src/ide` and `src/prj/ide` into `FUN_ROOT`;
3. runs `dcc32 funide.dpr` with the Fun unit search path and the IDE defines.

The resulting `funide.exe` is written to `<FUN_ROOT>\fun`, next to `fun.exe`.
Extra `dcc32` switches are passed through, e.g. `make-2009.bat -B`.

| Target          | Script                                  | Toolchain   |
| --------------- | --------------------------------------- | ----------- |
| Windows 32-bit  | `src/prj/ide/make-2006.bat`             | Delphi 2006 |
| Windows 32-bit  | `src/prj/ide/make-2009.bat`             | Delphi 2009 |

The IDE is Windows/VCL only, so there is no Linux or Free Pascal target.

---

## Syntax highlighting grammar

`syntaxes/fun.tmLanguage.yaml` is the upstream source that GitHub Linguist
vendors (as a git submodule) to provide syntax highlighting for `.fun` files:

- `vendor/grammars/fun` submodule points at this repository
- `grammars.yml`: `vendor/grammars/fun: [source.fun]`
- `languages.yml`: the `Fun` entry's `tm_scope` is `source.fun`

---

## License

MIT. See [LICENSE](LICENSE).
