TFunSyntax

tk

Sensitive

IdentStart '$', '_', '@'..'Z', 'a'..'z':: '$', '_', '@'..'Z', 'a'..'z', '0'..'9'::

TOKENTYPES

Identifier Foreground=$222222

Space

String  Foreground=$00BA7F|Background=$f0f0f0|Style=[fsUnderline]

Regex   Foreground=$ff4580|Background=$f0f0f0|Style=[fsItalic]

Number  Foreground=$2250F2

Symbol  Foreground=$00B9FF

Comment Foreground=clGray|Style=[fsItalic]

Key     Foreground=$EFA400|Style=[fsBold,fsItalic]

|><|

KEYS

if case loop try fun class
elsif else when except finally
then is while for to step in
end exit next raise return
use var do
new as atom
div mod not and or xor bit
true false null nil
this base result @

|><|

CHARS

'$', '_', '@'..'Z', 'a'..'z':: Ident
BeginProc
  if (fLine[Run] = '$') and (fLine[Run+1] in ['"', '''', '`']) then
  begin
    Inc(Run);
    RegexProc;
  end
  else
  begin
    fTokenID := IdentKind((fLine + Run));
    Inc(Run, fStringLen);
    while IsIdentChar(fLine[Run]) do Inc(Run);
  end;
EndProc

'0'..'9':: Number
BeginProc
  fTokenID := tkNumber;
  Inc(Run);
  while fLine[Run] in ['0'..'9'] do Inc(Run);
EndProc

'/', '%':: Regex
var
  i: integer;
  c: char;
BeginProc
  c := fLine[Run];
  if (c = '/') and (fLine[Run + 1] = '/') then
  begin
    Inc(Run);
    CommentProc;
    exit;
  end
  else
  begin
    i := Run + 1;
    if c in ['"', '''', '`'] then
    begin
      while true do
      begin
        while not (fLine[i] in [#0, #10, #13, c]) do Inc(i);
        case fLine[Run] of
           #0: NullProc;
          #10: LFProc;
          #13: CRProc;
        else
          break;
        end;
      end;
    end
    else
      while not (fLine[i] in [#0..' ', c]) do Inc(i)
    ;
    if fLine[i] = c then
    begin
      Inc(i);
      while fLine[i] in ['a'..'z'] do Inc(i);
      fTokenID := tkRegex;
      Run := i;
      exit;
    end;
  end;
  if c in ['"', '''', '`'] then
    fTokenID := tkRegex
  else
    SymbolProc
  ;
EndProc

'#':: Comment
BeginProc
  fTokenID := tkComment;
  Inc(Run);
  while not IsLineEnd(Run) do Inc(Run);
EndProc

'~', '!', '^', '&', '*', '(', ')', '-', '+', '=', '[', ']', '{', '}', '\', '|', ';', ':', ',', '.', '<', '>', '?':: Symbol
BeginProc
  fTokenID := tkSymbol;
  Inc(Run);
  if (fLine[Run-1] = '.') and (fLine[Run] = '#') then Inc(Run);
EndProc

|><|

ENCLOSEDBY

String,String1,",",MultiLine
String,String2,',',MultiLine
String,String3,`,`,MultiLine
Comment,Comment3,#*,#,MultiLine

|><|