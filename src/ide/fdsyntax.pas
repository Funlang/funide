unit fdsyntax;

{$I SynEdit.inc}

interface

uses
  Graphics,
  SynEditHighlighter,
  SynUnicode,
  Classes;

type
  IntPtr = {$IFDEF CPUX64}Int64{$ELSE}Integer{$ENDIF};

  TtkTokenKind = (
    tkComment,
    tkShebang,
    tkIndent,
    tkKey,
    tkNull,
    tkSpace,
    tkUnknown,
    tkValue,
    tkConstant,
    tkNumber
  );

  TRangeState = (
    rsUnknown,
    rsPreKey,
    rsAfterKey,
    rsString1_Key,
    rsString1_Value,
    rsString2_Key,
    rsString2_Value,
    rsString3_Key,
    rsString3_Value,
    rsString4_Key,
    rsString4_Value
  );

type
  TFdSyntax = class(TSynCustomHighlighter)
  private
    fRangeState: TRangeState;
    fLengthStringRemaining: IntPtr;
    fTokenID: TtkTokenKind;
    fCommentAttri: TSynHighlighterAttributes;
    fShebangAttri: TSynHighlighterAttributes;
    fIndentAttri: TSynHighlighterAttributes;
    fKeyAttri: TSynHighlighterAttributes;
    fSpaceAttri: TSynHighlighterAttributes;
    fValueAttri: TSynHighlighterAttributes;
    fConstantAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    procedure CommentProc;
    procedure WordProc;
    procedure NullProc;
    procedure SpaceProc;
    procedure IndentProc;
    procedure ValueProc;
    procedure UnknownProc;
    procedure CRProc;
    procedure LFProc;
    procedure DoStringProc(QuoteChar: WideChar; var RangeState: TRangeState; IsKey: Boolean);
    procedure String1OpenProc;
    procedure String1Proc;
    procedure String2OpenProc;
    procedure String2Proc;
    procedure String3OpenProc;
    procedure String3Proc;
    procedure String4OpenProc;
    procedure String4Proc;
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
    property ShebangAttri: TSynHighlighterAttributes read fShebangAttri write fShebangAttri;
    property IndentAttri: TSynHighlighterAttributes read fIndentAttri write fIndentAttri;
    property KeyAttri: TSynHighlighterAttributes read fKeyAttri write fKeyAttri;
    property SpaceAttri: TSynHighlighterAttributes read fSpaceAttri write fSpaceAttri;
    property ValueAttri: TSynHighlighterAttributes read fValueAttri write fValueAttri;
    property ConstantAttri: TSynHighlighterAttributes read fConstantAttri write fConstantAttri;
    property NumberAttri: TSynHighlighterAttributes read fNumberAttri write fNumberAttri;
  end;

implementation

{$WARN WIDECHAR_REDUCED OFF}

uses
  SynEditStrConst,
  SysUtils;

resourcestring
  SYNS_FilterFD = 'FD (*.fd)|*.fd';
  SYNS_LangFD = 'FD';
  SYNS_FriendlyLangFD = 'FD';
  SYNS_AttrIndent = 'Indent';
  SYNS_FriendlyAttrIndent = 'Indent';
  SYNS_AttrValue = 'Value';
  SYNS_FriendlyAttrValue = 'Value';
  SYNS_AttrConstant = 'Constant';
  SYNS_FriendlyAttrConstant = 'Constant';
  SYNS_AttrNumber = 'Number';
  SYNS_FriendlyAttrNumber = 'Number';
  SYNS_AttrShebang = 'Shebang';
  SYNS_FriendlyAttrShebang = 'Shebang';

constructor TFdSyntax.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fCaseSensitive := True;

  fCommentAttri := TSynHighLighterAttributes.Create(SYNS_AttrComment, SYNS_FriendlyAttrComment);
  fCommentAttri.Style := [fsItalic];
  fCommentAttri.Foreground := clGray;
  AddAttribute(fCommentAttri);

  fShebangAttri := TSynHighLighterAttributes.Create(SYNS_AttrShebang, SYNS_FriendlyAttrShebang);
  fShebangAttri.Style := [fsBold, fsItalic];
  fShebangAttri.Foreground := clRed;
  AddAttribute(fShebangAttri);

  fIndentAttri := TSynHighLighterAttributes.Create(SYNS_AttrIndent, SYNS_FriendlyAttrIndent);
  fIndentAttri.Style := [fsUnderline];
  fIndentAttri.Foreground := $cccccc;
  AddAttribute(fIndentAttri);

  fKeyAttri := TSynHighLighterAttributes.Create(SYNS_AttrReservedWord, SYNS_FriendlyAttrReservedWord);
  fKeyAttri.Style := [fsBold];
  fKeyAttri.Foreground := $EFA400;
  AddAttribute(fKeyAttri);

  fSpaceAttri := TSynHighLighterAttributes.Create(SYNS_AttrSpace, SYNS_FriendlyAttrSpace);
  AddAttribute(fSpaceAttri);

  fValueAttri := TSynHighLighterAttributes.Create(SYNS_AttrValue, SYNS_FriendlyAttrValue);
  fValueAttri.Style := [fsItalic];
  fValueAttri.Foreground := $00BA7F;
  fValueAttri.Background := $f8f8f8;
  AddAttribute(fValueAttri);

  fConstantAttri := TSynHighLighterAttributes.Create(SYNS_AttrConstant, SYNS_FriendlyAttrConstant);
  fConstantAttri.Style := [fsItalic];
  fConstantAttri.Foreground := $EFA400;
  AddAttribute(fConstantAttri);

  fNumberAttri := TSynHighLighterAttributes.Create(SYNS_AttrNumber, SYNS_FriendlyAttrNumber);
  fNumberAttri.Style := [fsItalic];
  fNumberAttri.Foreground := $2250F2;
  AddAttribute(fNumberAttri);

  SetAttributesOnChange(DefHighlightChange);
  fDefaultFilter := SYNS_FilterFD;
  ResetRange;
end;

procedure TFdSyntax.CommentProc;
begin
  fTokenID := tkComment;
  Inc(Run);
  if fLine[Run] = '!' then fTokenID := tkShebang;
  while not IsLineEnd(Run) do Inc(Run);
end;

procedure TFdSyntax.WordProc;
begin
  if fRangeState in [rsUnknown, rsPreKey] then
  begin
    fTokenID := tkKey;
    fRangeState := rsAfterKey;
  end
  else
    fTokenID := tkValue;
  while (fLine[Run] > #32) and not IsLineEnd(Run) do Inc(Run);
end;

procedure TFdSyntax.NullProc;
begin
  fTokenID := tkNull;
  Inc(Run);
end;

procedure TFdSyntax.IndentProc;
begin
  fTokenID := tkIndent;
  while (fLine[Run] in [' ', #9]) do Inc(Run);
  if fLine[Run] = '>' then
    while (fLine[Run] = '>') do Inc(Run)
  else if fLine[Run] in ['0'..'9'] then
  begin
    while (fLine[Run] in ['0'..'9']) do Inc(Run);
    if fLine[Run] = '>' then Inc(Run);
  end;
  while (fLine[Run] in [' ', #9]) and not IsLineEnd(Run) do Inc(Run);
  fRangeState := rsPreKey;
end;

procedure TFdSyntax.SpaceProc;
begin
  fTokenID := tkSpace;
  while (fLine[Run] in [' ', #9]) and not IsLineEnd(Run) do Inc(Run);
end;

procedure TFdSyntax.ValueProc;
var
  vStart: Integer;
  sValue: string;
  d: Double;
begin
  vStart := Run;
  while not IsLineEnd(Run) and (fLine[Run] <> '#') do
    Inc(Run);
  SetString(sValue, PWideChar(@fLine[vStart]), Run - vStart);

  if (sValue = 'true') or (sValue = 'false') or (sValue = 'null') or (sValue = '[]') or (sValue = '{}') then
    fTokenID := tkConstant
  else if TryStrToFloat(sValue, d) then
    fTokenID := tkNumber
  else
    fTokenID := tkValue;
end;

procedure TFdSyntax.UnknownProc;
begin
  fTokenID := tkUnknown;
  Inc(Run);
end;

procedure TFdSyntax.CRProc;
begin
  fTokenID := tkSpace;
  fRangeState := rsUnknown;
  Inc(Run);
  if fLine[Run] = #10 then Inc(Run);
end;

procedure TFdSyntax.LFProc;
begin
  fTokenID := tkSpace;
  fRangeState := rsUnknown;
  Inc(Run);
end;

procedure TFdSyntax.DoStringProc(QuoteChar: WideChar; var RangeState: TRangeState; IsKey: Boolean);
begin
  if IsKey then
    fTokenID := tkKey
  else
    fTokenID := tkValue;

  case fLine[Run] of
    #0:
      begin
        fTokenID := tkNull;
        Inc(Run);
      end;
    #10:
      Inc(Run);
    #13:
      begin
        Inc(Run);
        if fLine[Run] = #10 then Inc(Run);
      end;
  else
    repeat
      if fLine[Run] = QuoteChar then
      begin
        Inc(Run);
        RangeState := rsAfterKey;
        Break;
      end;
      if not IsLineEnd(Run) then Inc(Run);
    until IsLineEnd(Run);
  end;
end;

procedure TFdSyntax.String1OpenProc;
begin
  Inc(Run);
  if fRangeState in [rsUnknown, rsPreKey] then
  begin
    fRangeState := rsString1_Key;
    fTokenID := tkKey;
  end
  else
  begin
    fRangeState := rsString1_Value;
    fTokenID := tkValue;
  end;
end;

procedure TFdSyntax.String1Proc;
begin
  if fRangeState = rsString1_Key then
    DoStringProc('"', fRangeState, True)
  else
    DoStringProc('"', fRangeState, False);
end;

procedure TFdSyntax.String2OpenProc;
begin
  Inc(Run);
  if fRangeState in [rsUnknown, rsPreKey] then
  begin
    fRangeState := rsString2_Key;
    fTokenID := tkKey;
  end
  else
  begin
    fRangeState := rsString2_Value;
    fTokenID := tkValue;
  end;
end;

procedure TFdSyntax.String2Proc;
begin
  if fRangeState = rsString2_Key then
    DoStringProc('''', fRangeState, True)
  else
    DoStringProc('''', fRangeState, False);
end;

procedure TFdSyntax.String3OpenProc;
begin
  Inc(Run);
  if fRangeState in [rsUnknown, rsPreKey] then
  begin
    fRangeState := rsString3_Key;
    fTokenID := tkKey;
  end
  else
  begin
    fRangeState := rsString3_Value;
    fTokenID := tkValue;
  end;
end;

procedure TFdSyntax.String3Proc;
begin
  if fRangeState = rsString3_Key then
    DoStringProc('`', fRangeState, True)
  else
    DoStringProc('`', fRangeState, False);
end;

procedure TFdSyntax.String4OpenProc;
var
  PrefixChars, HexCount, HexStart, I: Integer;
  HexStr: string;
  Len: IntPtr;
  IsLengthPrefixed: Boolean;
begin
  Inc(Run, 2);

  if (Run < fLineLen) and (fLine[Run] in ['x', 'X']) then
  begin
    PrefixChars := 0;
    HexCount := 0;
    while (PrefixChars < 2) and (Run + PrefixChars < fLineLen) and
          (fLine[Run + PrefixChars] in ['x', 'X']) do
    begin
      if fLine[Run + PrefixChars] = 'x' then
        Inc(HexCount, 4)
      else
        Inc(HexCount, 6);
      Inc(PrefixChars);
    end;

    HexStart := Run + PrefixChars;

    if (HexCount > 0) and (HexStart + HexCount - 1 < fLineLen) then
    begin
      IsLengthPrefixed := True;
      for I := HexStart to HexStart + HexCount - 1 do
      begin
        if not (fLine[I] in ['0'..'9', 'a'..'f', 'A'..'F']) then
        begin
          IsLengthPrefixed := False;
          Break;
        end;
      end;

      if IsLengthPrefixed then
      begin
        HexStr := '';
        for I := HexStart to HexStart + HexCount - 1 do
          HexStr := HexStr + fLine[I];
        Len := IntPtr(StrToInt64Def('$' + HexStr, 0));

        Inc(Run, PrefixChars + HexCount);

        if fRangeState in [rsUnknown, rsPreKey] then
        begin
          fRangeState := rsString4_Key;
          fTokenID := tkSheBang; //tkKey;
        end
        else
        begin
          fRangeState := rsString4_Value;
          fTokenID := tkSheBang; //tkValue;
        end;

        fLengthStringRemaining := Len;
        if fLengthStringRemaining <= 0 then
          fRangeState := rsAfterKey;
        Exit;
      end;
    end;
  end;

  Dec(Run);
  if fRangeState in [rsUnknown, rsPreKey] then
  begin
    fRangeState := rsString3_Key;
    fTokenID := tkKey;
  end
  else
  begin
    fRangeState := rsString3_Value;
    fTokenID := tkValue;
  end;
end;

procedure TFdSyntax.String4Proc;
begin
  if fRangeState = rsString4_Key then
    fTokenID := tkKey
  else
    fTokenID := tkValue;

  while (fLengthStringRemaining > 0) and (Run < fLineLen) do
  begin
    if (fLine[Run] = '#') and (Run + 3 < fLineLen + 1) and
       (fLine[Run + 1] = '!') and
       (fLine[Run + 2] = '`') and
       (fLine[Run + 3] = '`') then
    begin
      fLengthStringRemaining := 0;
      fRangeState := rsUnknown;
      Exit;
    end;

    Inc(Run);
    Dec(fLengthStringRemaining);
  end;

  if fLengthStringRemaining <= 0 then
    fRangeState := rsAfterKey
  else if Run >= fLineLen then
  begin
    Inc(Run);
    Dec(fLengthStringRemaining);
  end;
end;

procedure TFdSyntax.Next;
begin
  fTokenPos := Run;
  case fRangeState of
    rsString1_Key, rsString1_Value: String1Proc;
    rsString2_Key, rsString2_Value: String2Proc;
    rsString3_Key, rsString3_Value: String3Proc;
    rsString4_Key, rsString4_Value: String4Proc;
  else
    case fLine[Run] of
      #0: NullProc;
      #10: LFProc;
      #13: CRProc;
      '"': String1OpenProc;
      '''': String2OpenProc;
      '`':
        if fLine[Run + 1] = '`' then
          String4OpenProc
        else
          String3OpenProc;
      '\':
        if (fLine[Run + 1] in ['"', '''', '`']) then
        begin
          Inc(Run);
          case fLine[Run] of
            '"': String1OpenProc;
            '''': String2OpenProc;
            '`': String3OpenProc;
          end;
        end
        else
          UnknownProc;
      '#': CommentProc;
      #1..#9, #11, #12, #14..#32:
        if fRangeState = rsUnknown then
          IndentProc
        else
          SpaceProc;
      else
        if (fRangeState = rsUnknown) and ((fLine[Run] = '>') or (fLine[Run] in ['0'..'9'])) then
          IndentProc
        else if fRangeState = rsAfterKey then
          ValueProc
        else
          WordProc;
    end;
  end;

  if (Run >= fLineLen + 1) and (fRangeState in [rsUnknown, rsPreKey, rsAfterKey]) then
    fRangeState := rsUnknown;

  inherited;
end;

function TFdSyntax.GetDefaultAttribute(Index: Integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := fValueAttri;
    SYN_ATTR_KEYWORD: Result := fKeyAttri;
    SYN_ATTR_STRING: Result := fValueAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    SYN_ATTR_SYMBOL: Result := fValueAttri;
  else
    Result := nil;
  end;
end;

function TFdSyntax.GetEol: Boolean;
begin
  Result := Run = fLineLen + 1;
end;

function TFdSyntax.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

function TFdSyntax.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case GetTokenID of
    tkComment: Result := fCommentAttri;
    tkShebang: Result := fShebangAttri;
    tkIndent: Result := fIndentAttri;
    tkKey: Result := fKeyAttri;
    tkSpace: Result := fSpaceAttri;
    tkValue: Result := fValueAttri;
    tkConstant: Result := fConstantAttri;
    tkNumber: Result := fNumberAttri;
    tkUnknown: Result := fValueAttri;
  else
    Result := nil;
  end;
end;

function TFdSyntax.GetTokenKind: Integer;
begin
  Result := Ord(fTokenId);
end;

function TFdSyntax.IsIdentChar(AChar: WideChar): Boolean;
begin
  Result := AChar > #32; //AChar in ['$', '_', '@'..'Z', 'a'..'z', '0'..'9'];
end;

function TFdSyntax.GetSampleSource: UnicodeString;
begin
  Result := '';
end;

function TFdSyntax.IsFilterStored: Boolean;
begin
  Result := fDefaultFilter <> SYNS_FilterFD;
end;

class function TFdSyntax.GetFriendlyLanguageName: UnicodeString;
begin
  Result := SYNS_FriendlyLangFD;
end;

class function TFdSyntax.GetLanguageName: string;
begin
  Result := SYNS_LangFD;
end;

procedure TFdSyntax.ResetRange;
begin
  fRangeState := rsUnknown;
  fLengthStringRemaining := 0;
end;

function TFdSyntax.GetRange: Pointer;
begin
  Result := Pointer(IntPtr(Ord(fRangeState)) or (IntPtr(fLengthStringRemaining) shl 4));
end;

procedure TFdSyntax.SetRange(Value: Pointer);
var
  V: IntPtr;
begin
  if Value = nil then
    ResetRange
  else
  begin
    V := IntPtr(Value);
    fRangeState := TRangeState(V and $F);
    fLengthStringRemaining := V shr 4;
  end;
end;

initialization
{$IFNDEF SYN_CPPB_1}
  RegisterPlaceableHighlighter(TFdSyntax);
{$ENDIF}
end.