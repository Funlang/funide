// Copyright (c) 2010-2026 Zhang Weidong <zwd@funlang.org>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
{+-----------------------------------------------------------------------------+
 | Class:       TFunSyntax
 | Created:     2012-09-17
 | Last change: 2012-09-17
 | Author:      fun
 | Description: Fun
 | Version:     1.0
 |
 | Copyright (c) 2012 fun. All rights reserved.
 |
 | Generated with SynGen.
 +----------------------------------------------------------------------------+}

{$IFNDEF QFUNSYNTAX}
unit funsyntax;
{$ENDIF}

{$I SynEdit.inc}

interface

uses
{$IFDEF SYN_CLX}
  QGraphics,
  //QSynEditTypes,
  QSynEditHighlighter,
  QSynUnicode,
{$ELSE}
  Graphics,
  //SynEditTypes,
  SynEditHighlighter,
  SynUnicode,
{$ENDIF}
  //SysUtils,
  Classes;

type
  TtkTokenKind = (
    tkComment,
    tkIdentifier,
    tkKey,
    tkNull,
    tkNumber,
    tkRegex,
    tkSpace,
    tkString,
    tkSymbol,
    tkUnknown);

  TRangeState = (rsUnKnown, rsString1, rsString2, rsString3, rsComment3);

  TProcTableProc = procedure of object;

  PIdentFuncTableFunc = ^TIdentFuncTableFunc;
  TIdentFuncTableFunc = function (Index: Integer): TtkTokenKind of object;

type
  TFunSyntax = class(TSynCustomHighlighter)
  private
    fRange: TRangeState;
    fTokenID: TtkTokenKind;
    fIdentFuncTable: array[0..78] of TIdentFuncTableFunc;
    fCommentAttri: TSynHighlighterAttributes;
    fIdentifierAttri: TSynHighlighterAttributes;
    fKeyAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    fRegexAttri: TSynHighlighterAttributes;
    fSpaceAttri: TSynHighlighterAttributes;
    fStringAttri: TSynHighlighterAttributes;
    fSymbolAttri: TSynHighlighterAttributes;
    function HashKey(Str: PWideChar): Cardinal;
    function Func64(Index: Integer): TtkTokenKind;
    function FuncAnd(Index: Integer): TtkTokenKind;
    function FuncAs(Index: Integer): TtkTokenKind;
    function FuncAtom(Index: Integer): TtkTokenKind;
    function FuncBase(Index: Integer): TtkTokenKind;
    function FuncBit(Index: Integer): TtkTokenKind;
    function FuncCase(Index: Integer): TtkTokenKind;
    function FuncClass(Index: Integer): TtkTokenKind;
    function FuncDiv(Index: Integer): TtkTokenKind;
    function FuncDo(Index: Integer): TtkTokenKind;
    function FuncElse(Index: Integer): TtkTokenKind;
    function FuncElsif(Index: Integer): TtkTokenKind;
    function FuncEnd(Index: Integer): TtkTokenKind;
    function FuncExcept(Index: Integer): TtkTokenKind;
    function FuncExit(Index: Integer): TtkTokenKind;
    function FuncFalse(Index: Integer): TtkTokenKind;
    function FuncFinally(Index: Integer): TtkTokenKind;
    function FuncFor(Index: Integer): TtkTokenKind;
    function FuncFun(Index: Integer): TtkTokenKind;
    function FuncIf(Index: Integer): TtkTokenKind;
    function FuncIn(Index: Integer): TtkTokenKind;
    function FuncIs(Index: Integer): TtkTokenKind;
    function FuncLoop(Index: Integer): TtkTokenKind;
    function FuncMod(Index: Integer): TtkTokenKind;
    function FuncNew(Index: Integer): TtkTokenKind;
    function FuncNext(Index: Integer): TtkTokenKind;
    function FuncNil(Index: Integer): TtkTokenKind;
    function FuncNot(Index: Integer): TtkTokenKind;
    function FuncNull(Index: Integer): TtkTokenKind;
    function FuncOr(Index: Integer): TtkTokenKind;
    function FuncRaise(Index: Integer): TtkTokenKind;
    function FuncResult(Index: Integer): TtkTokenKind;
    function FuncReturn(Index: Integer): TtkTokenKind;
    function FuncStep(Index: Integer): TtkTokenKind;
    function FuncThen(Index: Integer): TtkTokenKind;
    function FuncThis(Index: Integer): TtkTokenKind;
    function FuncTo(Index: Integer): TtkTokenKind;
    function FuncTrue(Index: Integer): TtkTokenKind;
    function FuncTry(Index: Integer): TtkTokenKind;
    function FuncUse(Index: Integer): TtkTokenKind;
    function FuncVar(Index: Integer): TtkTokenKind;
    function FuncWhen(Index: Integer): TtkTokenKind;
    function FuncWhile(Index: Integer): TtkTokenKind;
    function FuncXor(Index: Integer): TtkTokenKind;
    procedure CommentProc;
    procedure IdentProc;
    procedure NumberProc;
    procedure RegexProc;
    procedure SymbolProc;
    procedure UnknownProc;
    function AltFunc(Index: Integer): TtkTokenKind;
    procedure InitIdent;
    function IdentKind(MayBe: PWideChar): TtkTokenKind;
    procedure NullProc;
    procedure SpaceProc;
    procedure CRProc;
    procedure LFProc;
    procedure String1OpenProc;
    procedure String1Proc;
    procedure String2OpenProc;
    procedure String2Proc;
    procedure String3OpenProc;
    procedure String3Proc;
    procedure Comment3OpenProc;
    procedure Comment3Proc;
  protected
    function GetSampleSource: UnicodeString; override;
    function IsFilterStored: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    class function GetFriendlyLanguageName: UnicodeString; override;
    class function GetLanguageName: string; override;
    function GetRange: Pointer; override;
    procedure ResetRange; override;
    procedure SetRange(Value: Pointer); override;
    function GetDefaultAttribute(Index: Integer): TSynHighlighterAttributes; override;
    function GetEol: Boolean; override;
    function GetTokenID: TtkTokenKind;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: Integer; override;
    function IsIdentChar(AChar: WideChar): Boolean; override;
    procedure Next; override;
  published
    property CommentAttri: TSynHighlighterAttributes read fCommentAttri write fCommentAttri;
    property IdentifierAttri: TSynHighlighterAttributes read fIdentifierAttri write fIdentifierAttri;
    property KeyAttri: TSynHighlighterAttributes read fKeyAttri write fKeyAttri;
    property NumberAttri: TSynHighlighterAttributes read fNumberAttri write fNumberAttri;
    property RegexAttri: TSynHighlighterAttributes read fRegexAttri write fRegexAttri;
    property SpaceAttri: TSynHighlighterAttributes read fSpaceAttri write fSpaceAttri;
    property StringAttri: TSynHighlighterAttributes read fStringAttri write fStringAttri;
    property SymbolAttri: TSynHighlighterAttributes read fSymbolAttri write fSymbolAttri;
  end;

implementation

{$WARN WIDECHAR_REDUCED OFF}

uses
{$IFDEF SYN_CLX}
  QSynEditStrConst;
{$ELSE}
  SynEditStrConst;
{$ENDIF}

resourcestring
  SYNS_FilterFun = 'Fun (*.fun)|*.fun';
  SYNS_LangFun = 'Fun';
  SYNS_FriendlyLangFun = 'Fun';
  SYNS_AttrRegex = 'Regex';
  SYNS_FriendlyAttrRegex = 'Regex';

const
  KeyWords: array[0..43] of UnicodeString = (
    '@', 'and', 'as', 'atom', 'base', 'bit', 'case', 'class', 'div', 'do', 
    'else', 'elsif', 'end', 'except', 'exit', 'false', 'finally', 'for', 'fun', 
    'if', 'in', 'is', 'loop', 'mod', 'new', 'next', 'nil', 'not', 'null', 'or', 
    'raise', 'result', 'return', 'step', 'then', 'this', 'to', 'true', 'try', 
    'use', 'var', 'when', 'while', 'xor' 
  );

  KeyIndices: array[0..78] of Integer = (
    12, -1, 1, 37, 11, 36, 29, -1, -1, 38, -1, 20, 43, 9, -1, 19, 27, 16, 39, 
    -1, 40, -1, 34, 26, -1, 42, 28, -1, -1, -1, 41, -1, -1, -1, 7, 32, -1, -1, 
    -1, 3, -1, -1, 31, -1, -1, -1, 10, 0, 21, -1, 22, 33, 2, -1, 4, -1, -1, 35, 
    -1, 24, -1, 15, -1, -1, 23, -1, -1, -1, -1, -1, 18, 17, 13, 8, 25, 5, 6, 14, 
    30 
  );

procedure TFunSyntax.InitIdent;
var
  i: Integer;
begin
  for i := Low(fIdentFuncTable) to High(fIdentFuncTable) do
    if KeyIndices[i] = -1 then
      fIdentFuncTable[i] := AltFunc;

  fIdentFuncTable[47] := Func64;
  fIdentFuncTable[2] := FuncAnd;
  fIdentFuncTable[52] := FuncAs;
  fIdentFuncTable[39] := FuncAtom;
  fIdentFuncTable[54] := FuncBase;
  fIdentFuncTable[75] := FuncBit;
  fIdentFuncTable[76] := FuncCase;
  fIdentFuncTable[34] := FuncClass;
  fIdentFuncTable[73] := FuncDiv;
  fIdentFuncTable[13] := FuncDo;
  fIdentFuncTable[46] := FuncElse;
  fIdentFuncTable[4] := FuncElsif;
  fIdentFuncTable[0] := FuncEnd;
  fIdentFuncTable[72] := FuncExcept;
  fIdentFuncTable[77] := FuncExit;
  fIdentFuncTable[61] := FuncFalse;
  fIdentFuncTable[17] := FuncFinally;
  fIdentFuncTable[71] := FuncFor;
  fIdentFuncTable[70] := FuncFun;
  fIdentFuncTable[15] := FuncIf;
  fIdentFuncTable[11] := FuncIn;
  fIdentFuncTable[48] := FuncIs;
  fIdentFuncTable[50] := FuncLoop;
  fIdentFuncTable[64] := FuncMod;
  fIdentFuncTable[59] := FuncNew;
  fIdentFuncTable[74] := FuncNext;
  fIdentFuncTable[23] := FuncNil;
  fIdentFuncTable[16] := FuncNot;
  fIdentFuncTable[26] := FuncNull;
  fIdentFuncTable[6] := FuncOr;
  fIdentFuncTable[78] := FuncRaise;
  fIdentFuncTable[42] := FuncResult;
  fIdentFuncTable[35] := FuncReturn;
  fIdentFuncTable[51] := FuncStep;
  fIdentFuncTable[22] := FuncThen;
  fIdentFuncTable[57] := FuncThis;
  fIdentFuncTable[5] := FuncTo;
  fIdentFuncTable[3] := FuncTrue;
  fIdentFuncTable[9] := FuncTry;
  fIdentFuncTable[18] := FuncUse;
  fIdentFuncTable[20] := FuncVar;
  fIdentFuncTable[30] := FuncWhen;
  fIdentFuncTable[25] := FuncWhile;
  fIdentFuncTable[12] := FuncXor;
end;

{$Q-}
function TFunSyntax.HashKey(Str: PWideChar): Cardinal;
begin
  Result := 0;
  while IsIdentChar(Str^) do
  begin
    Result := Result * 870 + Ord(Str^) * 276;
    inc(Str);
  end;
  Result := Result mod 79;
  fStringLen := Str - fToIdent;
end;
{$Q+}

function TFunSyntax.Func64(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncAnd(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncAs(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncAtom(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncBase(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncBit(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncCase(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncClass(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncDiv(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncDo(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncElse(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncElsif(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncEnd(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncExcept(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncExit(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncFalse(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncFinally(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncFor(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncFun(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncIf(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncIn(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncIs(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncLoop(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncMod(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncNew(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncNext(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncNil(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncNot(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncNull(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncOr(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncRaise(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncResult(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncReturn(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncStep(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncThen(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncThis(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncTo(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncTrue(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncTry(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncUse(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncVar(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncWhen(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncWhile(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.FuncXor(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TFunSyntax.AltFunc(Index: Integer): TtkTokenKind;
begin
  Result := tkIdentifier;
end;

function TFunSyntax.IdentKind(MayBe: PWideChar): TtkTokenKind;
var
  Key: Cardinal;
begin
  fToIdent := MayBe;
  Key := HashKey(MayBe);
  if Key <= High(fIdentFuncTable) then
    Result := fIdentFuncTable[Key](KeyIndices[Key])
  else
    Result := tkIdentifier;
end;

procedure TFunSyntax.SpaceProc;
begin
  inc(Run);
  fTokenID := tkSpace;
  while (FLine[Run] <= #32) and not IsLineEnd(Run) do inc(Run);
end;

procedure TFunSyntax.NullProc;
begin
  fTokenID := tkNull;
  inc(Run);
end;

procedure TFunSyntax.CRProc;
begin
  fTokenID := tkSpace;
  inc(Run);
  if fLine[Run] = #10 then
    inc(Run);
end;

procedure TFunSyntax.LFProc;
begin
  fTokenID := tkSpace;
  inc(Run);
end;

procedure TFunSyntax.String1OpenProc;
begin
  Inc(Run);
  fRange := rsString1;
  fTokenID := tkString;
end;

procedure TFunSyntax.String1Proc;
begin
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
  else
    begin
      fTokenID := tkString;
      repeat
        if (fLine[Run] = '"') then
        begin
          Inc(Run, 1);
          fRange := rsUnKnown;
          Break;
        end;
        if not IsLineEnd(Run) then
          Inc(Run);
      until IsLineEnd(Run);
    end;
  end;
end;

procedure TFunSyntax.String2OpenProc;
begin
  Inc(Run);
  fRange := rsString2;
  fTokenID := tkString;
end;

procedure TFunSyntax.String2Proc;
begin
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
  else
    begin
      fTokenID := tkString;
      repeat
        if (fLine[Run] = '''') then
        begin
          Inc(Run, 1);
          fRange := rsUnKnown;
          Break;
        end;
        if not IsLineEnd(Run) then
          Inc(Run);
      until IsLineEnd(Run);
    end;
  end;
end;

procedure TFunSyntax.String3OpenProc;
begin
  Inc(Run);
  fRange := rsString3;
  fTokenID := tkString;
end;

procedure TFunSyntax.String3Proc;
begin
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
  else
    begin
      fTokenID := tkString;
      repeat
        if (fLine[Run] = '`') then
        begin
          Inc(Run, 1);
          fRange := rsUnKnown;
          Break;
        end;
        if not IsLineEnd(Run) then
          Inc(Run);
      until IsLineEnd(Run);
    end;
  end;
end;

procedure TFunSyntax.Comment3OpenProc;
begin
  Inc(Run);
  if (fLine[Run] = '*') then
  begin
    Inc(Run, 1);
    fRange := rsComment3;
    fTokenID := tkComment;
  end
  else
  begin
    //fTokenID := tkSymbol;
    Dec(Run);
    CommentProc;
  end;
end;

procedure TFunSyntax.Comment3Proc;
begin
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
  else
    begin
      fTokenID := tkComment;
      repeat
        if (fLine[Run] = '#') then
        begin
          Inc(Run, 1);
          fRange := rsUnKnown;
          Break;
        end;
        if not IsLineEnd(Run) then
          Inc(Run);
      until IsLineEnd(Run);
    end;
  end;
end;

constructor TFunSyntax.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fCaseSensitive := True;

  fCommentAttri := TSynHighLighterAttributes.Create(SYNS_AttrComment, SYNS_FriendlyAttrComment);
  fCommentAttri.Style := [fsItalic];
  fCommentAttri.Foreground := clGray;
  AddAttribute(fCommentAttri);

  fIdentifierAttri := TSynHighLighterAttributes.Create(SYNS_AttrIdentifier, SYNS_FriendlyAttrIdentifier);
  fIdentifierAttri.Foreground := $222222;
  AddAttribute(fIdentifierAttri);

  fKeyAttri := TSynHighLighterAttributes.Create(SYNS_AttrReservedWord, SYNS_FriendlyAttrReservedWord);
  fKeyAttri.Style := [fsBold, fsItalic];
  fKeyAttri.Foreground := $EFA400;
  AddAttribute(fKeyAttri);

  fNumberAttri := TSynHighLighterAttributes.Create(SYNS_AttrNumber, SYNS_FriendlyAttrNumber);
  fNumberAttri.Foreground := $2250F2;
  AddAttribute(fNumberAttri);

  fRegexAttri := TSynHighLighterAttributes.Create(SYNS_AttrRegex, SYNS_FriendlyAttrRegex);
  fRegexAttri.Style := [fsItalic];
  fRegexAttri.Foreground := $ff4580;
  fRegexAttri.Background := $f0f0f0;
  AddAttribute(fRegexAttri);

  fSpaceAttri := TSynHighLighterAttributes.Create(SYNS_AttrSpace, SYNS_FriendlyAttrSpace);
  AddAttribute(fSpaceAttri);

  fStringAttri := TSynHighLighterAttributes.Create(SYNS_AttrString, SYNS_FriendlyAttrString);
  fStringAttri.Style := [fsItalic];//[fsUnderline];
  fStringAttri.Foreground := $00BA7F;
  fStringAttri.Background := $f0f0f0;
  AddAttribute(fStringAttri);

  fSymbolAttri := TSynHighLighterAttributes.Create(SYNS_AttrSymbol, SYNS_FriendlyAttrSymbol);
  //fSymbolAttri.Style := [fsBold];
  fSymbolAttri.Foreground := $00B9FF;
  AddAttribute(fSymbolAttri);

  SetAttributesOnChange(DefHighlightChange);
  InitIdent;
  fDefaultFilter := SYNS_FilterFun;
  fRange := rsUnknown;
end;

procedure TFunSyntax.CommentProc;
begin
  fTokenID := tkComment;
  Inc(Run);
  while not IsLineEnd(Run) do Inc(Run);
end;

procedure TFunSyntax.IdentProc;
begin
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
end;

procedure TFunSyntax.NumberProc;
begin
  fTokenID := tkNumber;
  Inc(Run);
  while fLine[Run] in ['0'..'9'] do Inc(Run);
end;

procedure TFunSyntax.RegexProc;
var
  i: integer;
  c: char;
begin
  c := char(fLine[Run]);
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
        while not (char(fLine[i]) in [#0, #10, #13, c]) do Inc(i);
        case char(fLine[Run]) of
           #0: NullProc;
          #10: LFProc;
          #13: CRProc;
        else
          break;
        end;
      end;
    end
    else
      while not (char(fLine[i]) in [#0..' ', c]) do Inc(i)
    ;
    if char(fLine[i]) = c then
    begin
      Inc(i);
      while char(fLine[i]) in ['a'..'z'] do Inc(i);
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
end;

procedure TFunSyntax.SymbolProc;
begin
  fTokenID := tkSymbol;
  Inc(Run);
  if (fLine[Run-1] = '.') and (fLine[Run] = '#') then Inc(Run);
end;

procedure TFunSyntax.UnknownProc;
begin
  inc(Run);
  fTokenID := tkUnknown;
end;

procedure TFunSyntax.Next;
begin
  fTokenPos := Run;
  case fRange of
    rsString1: String1Proc;
    rsString2: String2Proc;
    rsString3: String3Proc;
    rsComment3: Comment3Proc;
  else
    case fLine[Run] of
      #0: NullProc;
      #10: LFProc;
      #13: CRProc;
      '"': String1OpenProc;
      '''': String2OpenProc;
      '`': String3OpenProc;
      '#': Comment3OpenProc;
      #1..#9, #11, #12, #14..#32: SpaceProc;
      //'#': CommentProc;
      '$', '_', '@'..'Z', 'a'..'z': IdentProc;
      '0'..'9': NumberProc;
      '/', '%': RegexProc;
      '~', '!', '^', '&', '*', '(', ')', '-', '+', '=', '[', ']', '{', '}', '\', '|', ';', ':', ',', '.', '<', '>', '?': SymbolProc;
    else
      UnknownProc;
    end;
  end;
  inherited;
end;

function TFunSyntax.GetDefaultAttribute(Index: Integer): TSynHighLighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := fIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := fKeyAttri;
    SYN_ATTR_STRING: Result := fStringAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    SYN_ATTR_SYMBOL: Result := fSymbolAttri;
  else
    Result := nil;
  end;
end;

function TFunSyntax.GetEol: Boolean;
begin
  Result := Run = fLineLen + 1;
end;

function TFunSyntax.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

function TFunSyntax.GetTokenAttribute: TSynHighLighterAttributes;
begin
  case GetTokenID of
    tkComment: Result := fCommentAttri;
    tkIdentifier: Result := fIdentifierAttri;
    tkKey: Result := fKeyAttri;
    tkNumber: Result := fNumberAttri;
    tkRegex: Result := fRegexAttri;
    tkSpace: Result := fSpaceAttri;
    tkString: Result := fStringAttri;
    tkSymbol: Result := fSymbolAttri;
    tkUnknown: Result := fIdentifierAttri;
  else
    Result := nil;
  end;
end;

function TFunSyntax.GetTokenKind: Integer;
begin
  Result := Ord(fTokenId);
end;

function TFunSyntax.IsIdentChar(AChar: WideChar): Boolean;
begin
  case AChar of
    '$', '_', '@'..'Z', 'a'..'z', '0'..'9':
      Result := True;
    else
      Result := False;
  end;
end;

function TFunSyntax.GetSampleSource: UnicodeString;
begin
  Result := 
    'Sample source for: '#13#10 +
    'Fun';
end;

function TFunSyntax.IsFilterStored: Boolean;
begin
  Result := fDefaultFilter <> SYNS_FilterFun;
end;

class function TFunSyntax.GetFriendlyLanguageName: UnicodeString;
begin
  Result := SYNS_FriendlyLangFun;
end;

class function TFunSyntax.GetLanguageName: string;
begin
  Result := SYNS_LangFun;
end;

procedure TFunSyntax.ResetRange;
begin
  fRange := rsUnknown;
end;

procedure TFunSyntax.SetRange(Value: Pointer);
begin
  fRange := TRangeState(Value);
end;

function TFunSyntax.GetRange: Pointer;
begin
  Result := Pointer(fRange);
end;

initialization
{$IFNDEF SYN_CPPB_1}
  RegisterPlaceableHighlighter(TFunSyntax);
{$ENDIF}
end.
