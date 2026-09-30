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
 | Class:       TRegexSyntax
 | Created:     2012-09-16
 | Last change: 2012-09-16
 | Author:      fun
 | Description: Fun
 | Version:     1.0
 |
 | Copyright (c) 2012 fun. All rights reserved.
 |
 | Generated with SynGen.
 +----------------------------------------------------------------------------+}

{$IFNDEF QREGEXSYNTAX}
unit regexsyntax;
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
    tkUnknown,
    tkNull,
    tkQuoting,
    tkEscape,
    tkMeta,
    tkQuantifier,
    tkClass,
    tkReference,
    tkError,
    tkGroup,
    tkGroup2,
    tkGroup3,
    tkGroup4,
    tkGroup5,
    tkGroup6
  );

  TRangeState = (rsUnKnown, rsClass, rsQuoting, rsComment);

type
  TRegexSyntax = class(TSynCustomHighlighter)
  private
    fRange: TRangeState;
    fTokenID: TtkTokenKind;
    fUnknownAttri: TSynHighlighterAttributes;
    fQuotingAttri: TSynHighlighterAttributes;
    fEscapeAttri: TSynHighlighterAttributes;
    fMetaAttri: TSynHighlighterAttributes;
    fQuantifierAttri: TSynHighlighterAttributes;
    fClassAttri: TSynHighlighterAttributes;
    fReferenceAttri: TSynHighlighterAttributes;
    fErrorAttri: TSynHighlighterAttributes;
    fGroupAttri: TSynHighlighterAttributes;
    fGroup2Attri: TSynHighlighterAttributes;
    fGroup3Attri: TSynHighlighterAttributes;
    fGroup4Attri: TSynHighlighterAttributes;
    fGroup5Attri: TSynHighlighterAttributes;
    fGroup6Attri: TSynHighlighterAttributes;
    fGroup: Integer;
    procedure EscapeProc;
    procedure MetaProc;
    procedure QuantifierProc;
    procedure QuantifierExProc;
    procedure ClassOpenProc;
    procedure ClassProc;
    procedure GroupStartProc;
    procedure GroupOrProc;
    procedure GroupEndProc;
    procedure UnknownProc;
    procedure NullProc;
    procedure CRProc;
    procedure LFProc;
    procedure SetGroup;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Next; override;
    function GetRange: Pointer; override;
    procedure ResetRange; override;
    procedure SetRange(Value: Pointer); override;
    function GetDefaultAttribute(Index: Integer): TSynHighlighterAttributes; override;
    function GetEol: Boolean; override;
    function GetTokenID: TtkTokenKind;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: Integer; override;
  end;

implementation

{$WARN WIDECHAR_REDUCED OFF}

uses
{$IFDEF SYN_CLX}
  QSynEditStrConst;
{$ELSE}
  SynEditStrConst;
{$ENDIF}

constructor TRegexSyntax.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fCaseSensitive := True;

  fUnknownAttri := TSynHighLighterAttributes.Create('Unknown', 'Unknown');
  fUnknownAttri.Foreground := $222222;
  AddAttribute(fUnknownAttri);

  fQuotingAttri := TSynHighLighterAttributes.Create('Quoting', 'Quoting');
  fQuotingAttri.Foreground := clWhite;
  fQuotingAttri.Background := $000000;
  AddAttribute(fQuotingAttri);

  fEscapeAttri := TSynHighLighterAttributes.Create('Escape', 'Escape');
  fEscapeAttri.Style := [fsItalic];
  fEscapeAttri.Foreground := $EFA400;
  fEscapeAttri.Background := $f0f0f0;
  AddAttribute(fEscapeAttri);

  fMetaAttri := TSynHighLighterAttributes.Create('Meta', 'Meta');
  fMetaAttri.Style := [fsBold];
  fMetaAttri.Foreground := clWhite;
  fMetaAttri.Background := $00B9FF;
  AddAttribute(fMetaAttri);

  fQuantifierAttri := TSynHighLighterAttributes.Create('Quantifier', 'Quantifier');
  fQuantifierAttri.Style := [fsBold];
  fQuantifierAttri.Foreground := $00B9FF;
  AddAttribute(fQuantifierAttri);

  fClassAttri := TSynHighLighterAttributes.Create('Class', 'Class');
  fClassAttri.Foreground := clWhite;
  fClassAttri.Background := $00BA7F;
  AddAttribute(fClassAttri);

  fReferenceAttri := TSynHighLighterAttributes.Create('Reference', 'Reference');
  fReferenceAttri.Style := [fsUnderline];
  fReferenceAttri.Foreground := $00BA7F;
  fReferenceAttri.Background := $f0f0f0;
  AddAttribute(fReferenceAttri);

  fErrorAttri := TSynHighLighterAttributes.Create('Error', 'Error');
  fErrorAttri.Style := [fsBold];
  fErrorAttri.Foreground := clWhite;
  fErrorAttri.Background := $2250F2;
  AddAttribute(fErrorAttri);

  fGroupAttri := TSynHighLighterAttributes.Create('Group', 'Group');
  fGroupAttri.Style := [fsBold];
  fGroupAttri.Foreground := clWhite;
  fGroupAttri.Background := $EFA400;
  AddAttribute(fGroupAttri);

  fGroup2Attri := TSynHighLighterAttributes.Create('Group2', 'Group2');
  fGroup2Attri.Style := [fsBold];
  fGroup2Attri.Foreground := $f0f0f0;
  fGroup2Attri.Background := $de9300;
  AddAttribute(fGroup2Attri);

  fGroup3Attri := TSynHighLighterAttributes.Create('Group3', 'Group3');
  fGroup3Attri.Style := [fsBold];
  fGroup3Attri.Foreground := $e0e0e0;
  fGroup3Attri.Background := $cd8200;
  AddAttribute(fGroup3Attri);

  fGroup4Attri := TSynHighLighterAttributes.Create('Group4', 'Group4');
  fGroup4Attri.Foreground := $d0d0d0;
  fGroup4Attri.Background := $dc7100;
  AddAttribute(fGroup4Attri);

  fGroup5Attri := TSynHighLighterAttributes.Create('Group5', 'Group5');
  fGroup5Attri.Foreground := $c0c0c0;
  fGroup5Attri.Background := $cb6000;
  AddAttribute(fGroup5Attri);

  fGroup6Attri := TSynHighLighterAttributes.Create('Group6', 'Group6');
  fGroup6Attri.Foreground := $b0b0b0;
  fGroup6Attri.Background := $ba5000;
  AddAttribute(fGroup6Attri);

  SetAttributesOnChange(DefHighlightChange);
  fRange := rsUnknown;
  fGroup := 0;
end;

procedure TRegexSyntax.Next;
begin
  fTokenPos := Run;
  case fRange of
    rsClass: ClassProc;
    
    rsQuoting:
    begin
      case fLine[Run] of
         #0: NullProc;
        #10: LFProc;
        #13: CRProc;
        '\':
        begin
          if fLine[Run+1] = 'E' then
            EscapeProc
          else
            UnknownProc
          ;
        end;
      else
        UnknownProc;
      end;
    end;
    
    rsComment:
    begin
      case fLine[Run] of
         #0: NullProc;
        #10: LFProc;
        #13: CRProc;
        ')':
        begin
          fRange := rsUnknown;
          GroupEndProc;
        end;
      else
        UnknownProc;
      end;
    end;
  else
    case fLine[Run] of
       #0: NullProc;
      #10: LFProc;
      #13: CRProc;
      '\': EscapeProc;
      '^', '.', '$': MetaProc;
      '*', '?', '+': QuantifierProc;
      '{': QuantifierExProc;
      '[': ClassOpenProc;
      '(': GroupStartProc;
      '|': GroupOrProc;
      ')': GroupEndProc;
    else
      UnknownProc;
    end;
  end;
  inherited;
end;

procedure TRegexSyntax.EscapeProc;
begin
  fTokenID := tkEscape;
  Inc(Run);
  case fLine[Run] of
    'c': Inc(Run, 2);
    
    'x', 'p', 'P':
    begin
      Inc(Run);
      if fLine[Run] = '{' then
      begin
        while (fLine[Run] <> '}') and not GetEol() do Inc(Run);
        Inc(Run);
      end
      else
        Inc(Run, 2)
      ;
    end;
    
    'Q':
    begin
      fTokenID := tkQuoting;
      Inc(Run);
      fRange := rsQuoting;
    end;
    
    'E':
    begin
      fTokenID := tkQuoting;
      Inc(Run);
      fRange := rsUnknown;
    end;
    
    '0'..'9':
    begin
      fTokenID := tkReference;
      repeat
        Inc(Run);
      until not (fLine[Run] in ['0'..'9']);
    end;
    
    'g', 'k':
    begin
      fTokenID := tkReference;
      if (fLine[Run] = 'g') and (fLine[Run+1] in ['0'..'9']) then
        Inc(Run, 2)
      else
      begin
        Inc(Run);
        case fLine[Run] of
          '{':
          begin
            while (fLine[Run] <> '}') and not GetEol() do Inc(Run);
            Inc(Run);
          end;

          '<':
          begin
            while (fLine[Run] <> '>') and not GetEol() do Inc(Run);
            Inc(Run);
          end;

          '''':
          begin
            Inc(Run);
            while (fLine[Run] <> '''') and not GetEol() do Inc(Run);
            Inc(Run);
          end;
        end;
      end;
    end;
    
    else
      Inc(Run);
  end;
  
  if GetEol then
  begin
    fTokenID := tkError;
    Run := fLineLen;
  end;
end;

procedure TRegexSyntax.MetaProc;
begin
  fTokenID := tkMeta;
  Inc(Run);
end;

procedure TRegexSyntax.QuantifierProc;
begin
  fTokenID := tkQuantifier;
  Inc(Run);
end;

procedure TRegexSyntax.QuantifierExProc;
var
  i: Integer;
begin
  fTokenID := tkUnknown;
  Inc(Run);
  i := Run;
  repeat
    if fLine[i] in ['0'..'9', ','] then
      Inc(i)
    else
      Exit
    ;
  until (fLine[i] = '}') or GetEol;
  fTokenID := tkQuantifier;
  Run := i+1;
end;

procedure TRegexSyntax.ClassOpenProc;
begin
  fRange := rsClass;
  fTokenID := tkClass;
  Inc(Run);
  if fLine[Run] = '^' then Inc(Run);
  
  if GetEol then
  begin
    fTokenID := tkError;
    Run := fLineLen;
  end;
end;

procedure TRegexSyntax.ClassProc;
begin
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;

    ']':
    begin
      fTokenID := tkClass;
      fRange := rsUnKnown;
      Inc(Run, 1);
    end;
    
    {'-':
    begin
      fTokenID := tkClass;
      Inc(Run, 1);
    end;}

    '\': EscapeProc;
    
    else
    begin
      fTokenID := tkUnKnown;
      Inc(Run, 1);
    end;
  end;
  
  if GetEol then
  begin
    fRange := rsUnKnown;
    fTokenID := tkError;
    Run := fLineLen;
  end;
end;

procedure TRegexSyntax.SetGroup;
begin
  if fGroup < 0 then
    fTokenID := tkError
  else
  begin
    fTokenID := TtkTokenKind(Integer(tkGroup) + fGroup);
    if Integer(fTokenID) > Integer(tkGroup6) then fTokenID := tkGroup6;
  end;
end;

procedure TRegexSyntax.GroupStartProc;
label toName, toErr;
begin
  Inc(Run);
  if fLine[Run] = '?' then
  begin
    Inc(Run);
    case fLine[Run] of
      '#':
      begin
        Inc(Run);
        fRange := rsComment;
      end;
      
      ':', '=', '!', '>', '|', 'R', '0'..'9', '&': Inc(Run);
      
      'P':
      begin
        Inc(Run);
        case fLine[Run] of
          '=', '>': Inc(Run);
          '<': goto toName;
          else goto toErr;
        end;
      end;
      
      '<':
      begin
      toName: 
        Inc(Run);
        if fLine[Run] in ['=', '!'] then
          Inc(Run)
        else
        begin
          while (fLine[Run] <> '>') and not GetEol do Inc(Run);
          Inc(Run);
        end;
      end;
      
      '''':
      begin
        Inc(Run);
        while (fLine[Run] <> '''') and not GetEol do Inc(Run);
        Inc(Run);
      end;
      
      //else goto toErr;
    end;
  end;

  if GetEol then
  begin
    Run := fLineLen;
  toErr:
    fTokenID := tkError;
    Exit;
  end;
  
  if fGroup < 0 then fGroup := 0;
  SetGroup;
  Inc(fGroup);
end;

procedure TRegexSyntax.GroupOrProc;
begin
  SetGroup;
  Inc(Run);
end;

procedure TRegexSyntax.GroupEndProc;
begin
  Dec(fGroup);
  SetGroup;
  Inc(Run);
end;

procedure TRegexSyntax.UnknownProc;
begin
  inc(Run);
  fTokenID := tkUnknown;
end;

procedure TRegexSyntax.NullProc;
begin
  fTokenID := tkNull;
  inc(Run);
  if (fGroup <> 0) or (fRange <> rsUnknown) then fTokenID := tkError;
end;

procedure TRegexSyntax.CRProc;
begin
  fTokenID := tkUnknown;
  inc(Run);
  if fLine[Run] = #10 then
    inc(Run);
end;

procedure TRegexSyntax.LFProc;
begin
  fTokenID := tkUnknown;
  inc(Run);
end;

function TRegexSyntax.GetDefaultAttribute(Index: Integer): TSynHighLighterAttributes;
begin
  Result := fUnknownAttri;
end;

function TRegexSyntax.GetEol: Boolean;
begin
  Result := Run >= fLineLen + 1;
end;

function TRegexSyntax.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

function TRegexSyntax.GetTokenAttribute: TSynHighLighterAttributes;
begin
  case GetTokenID of
    tkQuoting: Result := fQuotingAttri;
    tkEscape: Result := fEscapeAttri;
    tkMeta: Result := fMetaAttri;
    tkQuantifier: Result := fQuantifierAttri;
    tkClass: Result := fClassAttri;
    tkReference: Result := fReferenceAttri;
    tkError: Result := fErrorAttri;
    tkGroup: Result := fGroupAttri;
    tkGroup2: Result := fGroup2Attri;
    tkGroup3: Result := fGroup3Attri;
    tkGroup4: Result := fGroup4Attri;
    tkGroup5: Result := fGroup5Attri;
    tkGroup6: Result := fGroup6Attri;
  else
    Result := fUnknownAttri;
  end;
end;

function TRegexSyntax.GetTokenKind: Integer;
begin
  Result := Ord(fTokenId);
end;

procedure TRegexSyntax.ResetRange;
begin
  fRange := rsUnknown;
  fGroup := 0;
end;

procedure TRegexSyntax.SetRange(Value: Pointer);
begin
  fRange := TRangeState(Value);
  fGroup := 0;
end;

function TRegexSyntax.GetRange: Pointer;
begin
  Result := Pointer(fRange);
end;

initialization
{$IFNDEF SYN_CPPB_1}
  RegisterPlaceableHighlighter(TRegexSyntax);
{$ENDIF}
end.
