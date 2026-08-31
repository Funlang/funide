# Funide

Editor tooling for the [Fun](https://funlang.org) programming language.

## Contents

- [`syntaxes/fun.tmLanguage.yaml`](syntaxes/fun.tmLanguage.yaml) — the Fun
  [TextMate](https://macromates.com/manual/en/language_grammars) grammar
  (`scopeName: source.fun`) used for syntax highlighting. It is derived from
  the Fun implementation's lexer (`src/parse/bnf/lex.l`), grammar
  (`src/parse/bnf/yacc.y`) and keyword table (`src/parse/id.inc`).

The grammar is the upstream source that GitHub Linguist vendors (as a git
submodule) to provide syntax highlighting for `.fun` files:

- `vendor/grammars/fun` submodule points at this repository
- `grammars.yml`: `vendor/grammars/fun: [source.fun]`
- `languages.yml`: the `Fun` entry's `tm_scope` is `source.fun`

## License

MIT. See [LICENSE](LICENSE).
