# Funide

[Fun](https://funlang.org) 编程语言的 **funide** 集成开发环境与编辑器工具。

[English](README.md) · **简体中文**（本文件）

- 版本：**9.0**
- 网站：<https://funlang.org>
- 许可证：MIT，见 [LICENSE](LICENSE)

本仓库只维护 IDE 层：Delphi/VCL 桌面编辑器，以及 Fun 的 TextMate 语法文件。
Fun 语言本体（解释器、解析器、运行时库、正则引擎）在此**不做副本**，它直接
编译自相邻的 [`fun`](https://github.com/Funlang/fun) 项目，两者分开开源。

---

## 目录内容

- [`src/ide/`](src/ide) —— IDE 单元：主窗口与调试器胶合代码
  （`ide.pas`/`ide.dfm`）、Fun/Regex/FD 语法高亮（`funsyntax.pas`、
  `regexsyntax.pas`、`fdsyntax.pas`）及资源文件。
- [`src/prj/ide/`](src/prj/ide) —— Delphi 工程（`funide.dpr`、`funide.res`）
  与 Windows 构建脚本。
- [`syntaxes/fun.tmLanguage.yaml`](syntaxes/fun.tmLanguage.yaml) —— Fun 的
  [TextMate](https://macromates.com/manual/en/language_grammars) 语法文件
  （`scopeName: source.fun`），由 Fun 实现的词法（`src/parse/bnf/lex.l`）、
  文法（`src/parse/bnf/yacc.y`）和关键字表（`src/parse/id.inc`）派生而来。

---

## 仓库结构

```text
funide/
├── src/
│   ├── ide/                  # IDE 单元（funide.exe）
│   └── prj/ide/              # funide.dpr + Windows 构建脚本
└── syntaxes/
    └── fun.tmLanguage.yaml   # Fun TextMate 语法
```

---

## 与 `fun` 项目的关系

funide 不包含 Fun 语言本体。`funide.dpr` 和 `ide.pas` 直接链接 `fun` 的源码：

- `funide.dpr` 用相对路径引用 Fun 的正则引擎：

  ```pascal
  ide  in '..\..\ide\ide.pas'          // 本仓库
  pcrd in '..\..\regex\pcre\pcrd.pas'  // `fun` 项目
  pcre in '..\..\regex\pcre\pcre.pas'  // `fun` 项目
  ```

- `ide.pas` 按单元名引用 Fun 单元：

  ```pascal
  uses fun, base, core, host, parse, pcre, ui, io;
  ```

这些相对路径和单元名，只有在 IDE 层位于 **`fun` 源码树内部**时才能解析。
因此构建脚本会先把本仓库的 `src/ide`、`src/prj/ide` 并入 `fun` 检出目录，
再行编译：

```text
funide/src/ide      ->  <FUN_ROOT>\src\ide
funide/src/prj/ide  ->  <FUN_ROOT>\src\prj\ide
```

Fun 单元（`src/core`、`src/lib`、`src/parse`、`src/regex`、`src/3rd`、
`src/utils`）原样取自 `<FUN_ROOT>`，其路径填入编译器的单元搜索路径（`-U`）。
这样 Fun 实现只有一份，IDE 则留在本仓库维护。

构建时的目录结构如下：

```text
<FUN_ROOT>/                          # 一份 `fun` 项目检出
├── src/
│   ├── core/  lib/  lib/ui/  parse/  regex/  regex/pcre/  utils/  3rd/   # 来自 `fun`
│   ├── ide/                          # 由 funide/src/ide 复制而来
│   └── prj/
│       ├── fun/                      # 来自 `fun`
│       └── ide/                      # 由 funide/src/prj/ide 复制而来
└── fun/                              # 发行目录；funide.exe 输出到此处
```

复制进去的文件在 `fun` 检出中显示为未跟踪文件，这是预期行为：IDE 源码在此
维护，不在那边维护。

---

## 构建

`funide.exe` 是用 Delphi 编译的 32 位 Windows VCL 程序。

### 前置条件

| 项目 | 说明 |
| ---- | ---- |
| 一份 `fun` 检出 | funide 所编译依赖的语言源码。用 `FUN_ROOT` 指向它。 |
| Delphi 2006 或 2009 | `DELPHI2006` / `DELPHI2009` 供 `make-2006.bat` / `make-2009.bat` 使用。2006 构建为 ANSI，2009 构建为 Unicode。 |
| [SynEdit](https://github.com/SynEdit/SynEdit) | 编辑器组件。`SYNCEDIT` 指向包含 `SynEdit.inc` 与 `SynEdit*.pas` 的目录。 |
| [VirtualTrees](https://github.com/Virtual-TreeView/Virtual-TreeView) | 树形控件。`VST` 指向包含 `VirtualTrees.pas` 的目录。 |
| PCRE 8（8 位） | Fun 正则引擎所需。按 `fun` 项目 `README` 中 `src/regex/pcre/make.bat` 的说明构建。 |

SynEdit 与 VirtualTrees 为第三方组件，本仓库不附带。

### 工具链配置

所有与本机相关的路径集中在一个文件
[`src/prj/ide/setenv.bat`](src/prj/ide/setenv.bat)，其写法对照
`fun/src/prj/fun/setenv.bat`。修改一次即可，也可先在命令行里预设变量：

| 变量 | 含义 | 默认值 |
| ---- | ---- | ------ |
| `FUN_ROOT` | `fun` 检出的根目录 | `..\..\..\..\fun`（本仓库的同级目录） |
| `DELPHI2006` | Delphi 2006 安装根目录 | `D:\Borland\Delphi2006` |
| `DELPHI2009` | Delphi 2009 安装根目录 | `D:\Borland\Delphi2009` |
| `SYNCEDIT` | SynEdit 源码目录 | `D:\Delphi\SynEdit\Source` |
| `VST` | VirtualTrees 源码目录 | `D:\Delphi\VirtualTreeviewV5.5.3\Source` |

所有 `if not defined` 判断都会让你事先设置的值优先。

### 构建步骤

```text
cd src\prj\ide
make-2009.bat            # 或：make-2006.bat
```

`make-2009.bat`：

1. 从 `setenv.bat` 读取工具链；
2. 调用 `sync-ide.bat`，把 `src/ide`、`src/prj/ide` 复制进 `FUN_ROOT`；
3. 用 Fun 的单元搜索路径与 IDE 宏定义运行 `dcc32 funide.dpr`。

生成的 `funide.exe` 写入 `<FUN_ROOT>\fun`，与 `fun.exe` 同目录。
额外的 `dcc32` 开关会原样透传，例如 `make-2009.bat -B`。

| 目标 | 脚本 | 工具链 |
| ---- | ---- | ------ |
| Windows 32 位 | `src/prj/ide/make-2006.bat` | Delphi 2006 |
| Windows 32 位 | `src/prj/ide/make-2009.bat` | Delphi 2009 |

IDE 仅支持 Windows/VCL，因此没有 Linux 或 Free Pascal 目标。

---

## 语法高亮（TextMate）

`syntaxes/fun.tmLanguage.yaml` 是 GitHub Linguist 以 git 子模块方式收录的
上游源码，用于 `.fun` 文件的语法高亮：

- `vendor/grammars/fun` 子模块指向本仓库
- `grammars.yml`：`vendor/grammars/fun: [source.fun]`
- `languages.yml`：`Fun` 词条的 `tm_scope` 为 `source.fun`

---

## 许可证

MIT，见 [LICENSE](LICENSE)。
