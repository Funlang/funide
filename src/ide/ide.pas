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
unit ide;

interface

uses fun, base, core, host, parse, pcre, ui, io, funsyntax, regexsyntax, fdsyntax,
  Windows, SysUtils, Classes, Messages, Graphics, Controls, ComCtrls, ExtCtrls, CommCtrl,
  Forms, Menus, Buttons, Dialogs, AppEvnts, ActnList, ImgList, XPMan, ShellAPI,
  SynEdit, SynEditMiscClasses, SynEditTextBuffer, SynEditTypes, SynEditOptionsDialog, SynUnicode,
  VirtualTrees, StdCtrls, ToolWin, Math, SynEditHighlighter;

type
  ArrayOfByte = array of byte;
  TfDebugMode   = (dmGo, dmInto, dmOver, dmMore, dmOut);

  TfFile = class;
  TfEdit = class;
  PfData = ^TfData;
  TSplitterBase = ExtCtrls.TSplitter;
  TPageControlBase = ComCtrls.TPageControl;

  PHighLightRange = ^THighLightRange;
  THighLightRange = record
    StartPt, EndPt: TBufferCoord;
  end;

  TMemo = class(TCustomSynEdit)
  public
    constructor Create(AOwner: TComponent); override;
    function CaretPos: TPoint;
  published
    property Align;
    property Constraints;
    property OnKeyDown;
    property OnKeyPress;
    property ScrollBars;
    property TabOrder;
  end;
  
  TSplitter = class(TSplitterBase)
  private
    fInGrab: Boolean;
    fMouseIn: Boolean;
    GrabRect: TRect;
    OldSize: Integer;
    TempBrush: TBitmap;
    procedure CMMouseEnter(var AMsg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMsg: TMessage); message CM_MOUSELEAVE;
    function GetGrabRect: TRect;
    function GrabLength: Integer;
    function InGrabRect(X, Y: Integer): Boolean;
    property MouseIn: Boolean read fMouseIn;
  protected
    function DoCanResize(var NewSize: Integer): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure Resize; override;
  public
    destructor Destroy; override;
  end;
  
  TPageControl = class(TPageControlBase)
  private
    procedure TCMAdjustRect(var Msg: TMessage); message TCM_ADJUSTRECT;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
  end;
  
  CdParser = class(CParser)
  private
    f: TfFile;
  protected
    procedure OnParse(p: CParser); overload; override;
    procedure OnParse(n: CRune); overload; override;
    procedure OnParse(const fn: fun.str; var s: fun.str; m: core.CModu = nil); overload; override;
  public
    procedure DoError(const s: fun.str); overload; override;
  end;
  
  CdRunner = class(CEnv2)
  private
    lastOver: CNode;
  public
    ret: fun.str;
    function clone: CEnv; override;
    procedure echo(const s: fun.str); override;
    procedure trace(n: CNode); override;
    procedure traced(n: CNode; tracing: fun.bool = false); override;
  end;
  
  TfData = record
    Level: Integer;
    Index: Integer;
    Image: Integer;
    Edit: TfEdit;
  end;
  
  TfTree = class(TVirtualStringTree)
  public
    constructor Create(AOwner: TComponent); override;
  end;
  
  TfEdit = class(TCustomSynEdit)
  private
    f: TfFile;
    fFdSyntax: TSynCustomHighlighter;
    FFileName: string;
    fFunSyntax: TSynCustomHighlighter;
    FBracketLine1: Integer;
    FBracketLine2: Integer;
    FImageList: TImageList;
    FPrevCaretY: Integer;
    FSearchBookmarkLines: TList;
    FSearchHighlights: TList;
    fStates: ArrayOfByte;
    procedure EditorPaintTransient(Sender: TObject; Canvas: TCanvas; TransientType: TTransientType);
    function BracketMatch(out Match: TBufferCoord): Boolean;
    procedure GutterClick(Sender: TObject; Button: TMouseButton; X, Y, Line: Integer; Mark: TSynEditMark);
    procedure GutterGetText(Sender: TObject; aLine: Integer; var aText: UnicodeString);
    procedure GutterPaint(Sender: TObject; aLine: Integer; X, Y: Integer);
    procedure StatusChange(Sender: TObject; Changes: TSynStatusChanges);
  protected
    BOM: Boolean;
    Encoding: TSynEncoding;
    LastTime: TDateTime;
    function DoOnSpecialLineColors(Line: Integer; var Foreground, Background: TColor): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClearSearchHighlights;
    function CountMark: Integer;
    function DisplayName: string;
    function IsBookmark(Line: Integer): Boolean;
    function IsBreakLine(Line: Integer): Boolean;
    function IsBreakPoint(Line: Integer): Boolean;
    function IsCodeLine(Line: Integer): Boolean;
    procedure Load;
    procedure ReLoad(const AEncoding: TSynEncoding);
    procedure Save;
    procedure SetSearchHighlights(AList: TList);
    procedure ToggleAllMarks(Mark: Integer);
    procedure ToggleMark(Line, Mark: Integer);
    property FileName: string read FFileName write FFileName;
    property ImageList: TImageList read FImageList write FImageList;
  end;
  
  TfTab = class(TTabSheet)
  private
    FEdit: TfEdit;
    function GetFileName: string;
    function GetTitle: string;
    procedure SetFileName(const Value: string);
    procedure SetTitle(const Value: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Load;
    procedure Save;
    property Edit: TfEdit read FEdit;
    property FileName: string read GetFileName write SetFileName;
    property Title: string read GetTitle write SetTitle;
  end;
  
  TfSearch = class(TSynEditSearchCustom)
  private
    fLengths: TList;
    fPositions: TList;
    fRegex: CPcre;
  protected
    function GetLength(Index: Integer): Integer; override;
    function GetPattern: UnicodeString; override;
    function GetResult(Index: Integer): Integer; override;
    function GetResultCount: Integer; override;
    procedure SetOptions(const Value: TSynSearchOptions); override;
    procedure SetPattern(const Value: UnicodeString); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function FindAll(const NewText: UnicodeString): Integer; override;
    function Replace(const aOccurrence, aReplacement: UnicodeString): UnicodeString; override;
  end;
  
  TfFile = class(TObject)
    Name: string;
    Node: Pointer;
  private
    fCodes: array of CRune;
    FEdit: TfEdit;
    procedure SetEdit(Value: TfEdit);
  public
    function hasCode(line: fun.int): Boolean;
    function sameCode(n: CRune): Boolean;
    property Edit: TfEdit read FEdit write SetEdit;
  end;
  
  TfFiles = class(TObject)
  private
    f: TfFile;
    Files: TList;
    function GetFS(Index: Integer): TfFile;
  public
    constructor Create;
    destructor Destroy; override;
    function ActiveFile(n: CRune): TfFile;
    function Add(const fn: string; edit: TfEdit; dontCreate: Boolean = False): TfFile;
    function Count: Integer;
    function CountVisible: Integer;
    function Find(const fn: string; isAdd: boolean = false): TfFile;
    function IsBreakpoint(n: CRune): Boolean;
    function Visible(i: Integer): Boolean;
    property FS[Index: Integer]: TfFile read GetFS; default;
  end;
  
  TfIDE = class(TForm)
    aAbout: TAction;
    aBreakPoint: TAction;
    aClear: TAction;
    aClearAll: TAction;
    aClearBookmarks: TAction;
    aClearBreakpoints: TAction;
    aClose: TAction;
    aCloseAll: TAction;
    aCloseOthers: TAction;
    aCollapse: TAction;
    aCopy: TAction;
    acts: TActionList;
    aCut: TAction;
    aExpand: TAction;
    aFind: TAction;
    aFindAll: TAction;
    aFindMatchCase: TAction;
    aFindNext: TAction;
    aFindPrev: TAction;
    aFindRegex: TAction;
    aFindSelected: TAction;
    aFindWholeWord: TAction;
    aHelp: TAction;
    aNew: TAction;
    aOpen: TAction;
    aOptions: TAction;
    aPaste: TAction;
    aPause: TAction;
    appe: TApplicationEvents;
    aRedo: TAction;
    aReplace: TAction;
    aReplaceAll: TAction;
    aRun: TAction;
    aRunOut: TAction;
    aRunUni: TAction;
    aRunUniCN: TAction;
    aSave: TAction;
    aSaveAs: TAction;
    aSpecChar: TAction;
    aStepInto: TAction;
    aStepMore: TAction;
    aStepOut: TAction;
    aStepOver: TAction;
    aStop: TAction;
    aUndo: TAction;
    aWordWrap: TAction;
    bCopy: TToolButton;
    bCut: TToolButton;
    bFind: TToolButton;
    bNew: TToolButton;
    bOpen: TToolButton;
    bOptions: TToolButton;
    bPaste: TToolButton;
    bRedo: TToolButton;
    bSave: TToolButton;
    bSpecChar: TToolButton;
    btn1: TToolButton;
    btn2: TToolButton;
    btn3: TToolButton;
    btn4: TToolButton;
    btn5: TToolButton;
    btn6: TToolButton;
    btn7: TToolButton;
    btn8: TToolButton;
    btnAbout: TToolButton;
    btnBreakPoint: TToolButton;
    btnClear: TToolButton;
    btnClearAll: TToolButton;
    btnClearBookmarks: TToolButton;
    btnClearBreakpoints: TToolButton;
    btnCollapse: TToolButton;
    btnExpand: TToolButton;
    btnFindAll: TToolButton;
    btnFindMatchCase: TToolButton;
    btnFindNext: TToolButton;
    btnFindPrev: TToolButton;
    btnFindRegex: TToolButton;
    btnFindSelected: TToolButton;
    btnFindWholeWord: TToolButton;
    btnHelp: TToolButton;
    btnPause: TToolButton;
    btnReplace: TToolButton;
    btnReplaceAll: TToolButton;
    btnRun: TToolButton;
    btnStepInto: TToolButton;
    btnStepMore: TToolButton;
    btnStepOut: TToolButton;
    btnStepOver: TToolButton;
    btnStop: TToolButton;
    bUndo: TToolButton;
    bWordWrap: TToolButton;
    dlgOpen: TOpenDialog;
    dlgSave: TSaveDialog;
    il1: TImageList;
    miCopy: TMenuItem;
    miCut: TMenuItem;
    miPaste: TMenuItem;
    miRedo: TMenuItem;
    miRunOut: TMenuItem;
    miRunUni: TMenuItem;
    miRunUniCN: TMenuItem;
    miSaveAs: TMenuItem;
    miTabClose: TMenuItem;
    miTabCloseAll1: TMenuItem;
    miTabCloseOthers: TMenuItem;
    miUndo: TMenuItem;
    mmoFind: TMemo;
    mmoReplace: TMemo;
    pc: TPanel;
    pmEdit: TPopupMenu;
    pmFindPresets: TPopupMenu;
    pmOpen: TPopupMenu;
    pmRun: TPopupMenu;
    pmSave: TPopupMenu;
    pmTab: TPopupMenu;
    pr: TPanel;
    prb: TPanel;
    prc: TPanel;
    spl1: TSplitter;
    spl2: TSplitter;
    spl3: TSplitter;
    stats: TStatusBar;
    tabs: TPageControl;
    tb: TToolBar;
    tlb1: TToolBar;
    tlb2: TToolBar;
    xp1: TXPManifest;
    procedure aAboutExecute(Sender: TObject);
    procedure aBreakPointExecute(Sender: TObject);
    procedure aClearAllExecute(Sender: TObject);
    procedure aClearBookmarksExecute(Sender: TObject);
    procedure aClearBreakpointsExecute(Sender: TObject);
    procedure aClearExecute(Sender: TObject);
    procedure aCloseAllExecute(Sender: TObject);
    procedure aCloseExecute(Sender: TObject);
    procedure aCloseOthersExecute(Sender: TObject);
    procedure aCollapseExecute(Sender: TObject);
    procedure aCopyExecute(Sender: TObject);
    procedure aCutExecute(Sender: TObject);
    procedure aExpandExecute(Sender: TObject);
    procedure aFindAllExecute(Sender: TObject);
    procedure aFindExecute(Sender: TObject);
    procedure aFindMatchCaseExecute(Sender: TObject);
    procedure aFindNextExecute(Sender: TObject);
    procedure aFindPrevExecute(Sender: TObject);
    procedure aFindRegexExecute(Sender: TObject);
    procedure aFindSelectedExecute(Sender: TObject);
    procedure aFindWholeWordExecute(Sender: TObject);
    procedure aHelpExecute(Sender: TObject);
    procedure aNewExecute(Sender: TObject);
    procedure aOpenExecute(Sender: TObject);
    procedure aOptionsExecute(Sender: TObject);
    procedure aPasteExecute(Sender: TObject);
    procedure aPauseExecute(Sender: TObject);
    procedure appeHint(Sender: TObject);
    procedure appeIdle(Sender: TObject; var Done: Boolean);
    procedure aRedoExecute(Sender: TObject);
    procedure aReplaceAllExecute(Sender: TObject);
    procedure aReplaceExecute(Sender: TObject);
    procedure aRunExecute(Sender: TObject);
    procedure aRunOutExecute(Sender: TObject);
    procedure aRunUniCNExecute(Sender: TObject);
    procedure aRunUniExecute(Sender: TObject);
    procedure aSaveAsExecute(Sender: TObject);
    procedure aSaveExecute(Sender: TObject);
    procedure aSpecCharExecute(Sender: TObject);
    procedure aStepIntoExecute(Sender: TObject);
    procedure aStepMoreExecute(Sender: TObject);
    procedure aStepOutExecute(Sender: TObject);
    procedure aStepOverExecute(Sender: TObject);
    procedure aStopExecute(Sender: TObject);
    procedure aUndoExecute(Sender: TObject);
    procedure aWordWrapExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure mmoFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PresetItemClick(Sender: TObject);
    procedure statsClick(Sender: TObject);
  private
    DebugMode: TfDebugMode;
    dlgOptions: TSynEditOptionsDialog;
    Files: TfFiles;
    fInis: TStrings;
    fLogs: TStrings;
    fOptions: TSynEditorOptionsContainer;
    fPresetFile: string;
    IsBreaked: Boolean;
    IsRunning: Boolean;
    lastWord: fun.str;
    root: CRun;
    vtNodes: TfTree;
    procedure AddLog(const f: string);
    // T3: clickable output lines
    function LastErrorPos: string;
    function LocFromOutputLine(const line: string; out fn: string; out row: Integer): Boolean;
    procedure mmoReplaceDblClick(Sender: TObject);
    procedure ShowStatus(const s: string);
    // T5: jump to the file named by a `use '<file>'` string literal
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure WMGotoUse(var msg: TMessage); message WM_USER + 200; // deferred Ctrl+Click jump
    function UseStringAtCaret(out s: string): Boolean;
    function ResolveUseFile(const f: string): string;
    function GotoUseAtCaret: Boolean;
    // T6: `>stack` command line
    function StackText: string;
    function CheckExists(const f: string): Boolean;
    procedure ClearTree(node: PVirtualNode; mark: Integer = 0);
    procedure DoClearAll(mark: Integer);
    procedure DropFiles(Sender: TObject; X, Y: Integer; Files: TUnicodeStrings);
    function EvalExpr(const s: string): string;
    procedure Evaluate;
    function GetSearchOptions(so: TSynSearchOptions = []): TSynSearchOptions;
    function IniFile: string;
    procedure LoadFindPresets;
    procedure LoadLogs;
    procedure LocateActiveFileInTree;
    function LogFile: string;
    procedure NewTab;
    procedure OpenTab(const f: string);
    procedure RefreshTree;
    procedure Search(so: TSynSearchOptions = []);
    procedure TreeFocusChange(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
    procedure TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex:
            Integer);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: UnicodeString);
    procedure TreeInitChildren(Sender: TBaseVirtualTree; Node: PVirtualNode; var ChildCount: Cardinal);
    procedure TreeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure UpdateStatus(Sender: TObject = nil);
    procedure WMDropFiles(var msg: TMessage); message WM_DropFiles;
  protected
    function DoDebugCmd(const s: string): string;
    procedure DoRun;
    procedure DoStep(dm: TfDebugMode);
  public
    function ActiveEdit: TfEdit;
    procedure AddFile(const fn: string; edit: TfEdit = nil);
    procedure Output(const s: string; len: Integer = 4*1024*1024);
    procedure RemFile(const fn: string);
  end;
  

function FindIDE: Boolean;

var
  fIDE: TfIDE;

implementation

{$R *.dfm}

const
  ImageModified = 10;
  ImageSaved    =  9;

  ImgClass      =  5;
  ImgBreakLine  =  4;
  ImgBreakPoint =  3;
  ImgBreakFake  =  2;
  ImgBookmark   =  1;

var Old: Integer = 9;
var DontUpdate: Boolean = false;

function IdePath(): string;
begin
  result := ExtractFilePath(ExpandFileName(ParamStr(0))); // fIDE.Caption := result;
end;

function GetTime(const fn: string): TDateTime;
var
  Handle: THandle;
  FindData: TWin32FindData;
  SystemTime: TSystemTime;
begin
  Result := 0.0;
  try
    Handle := FindFirstFile(PChar(fn), FindData);
    if Handle <> INVALID_HANDLE_VALUE then
    begin
      Windows.FindClose(Handle);
      FileTimeToSystemTime(FindData.ftLastWriteTime, SystemTime);
      result := SystemTimeToDateTime(SystemTime);
    end;
  except
  end;
end;


//==============================================================
procedure CdParser.DoError(const s: fun.str);
begin
  raise Exception.create(s);
end;

procedure CdParser.OnParse(p: CParser);
begin
  f := CdParser(p).f;
end;

procedure CdParser.OnParse(n: CRune);
begin
  if (n is CFun) or not (n is CRune) then exit;
  if f = nil then with fIDE do
  begin
    f := Files.Add(ActiveEdit.DisplayName, ActiveEdit);
    SetLength(f.fCodes, 0);
    SetLength(f.fCodes, f.Edit.Lines.Count + 1);
  end;
  if n.row > High(f.fCodes) then SetLength(f.fCodes, n.row * 2);
  if f.fCodes[n.row] = nil then f.fCodes[n.row] := n;
end;

procedure CdParser.OnParse(const fn: fun.str; var s: fun.str; m: core.CModu = nil);
begin
  with fIDE do
  begin
    f := Files.Find(fn, true);
    if f.Edit <> nil then
    begin
      s := f.Edit.Text;
      SetLength(f.fCodes, 0);
      SetLength(f.fCodes, f.Edit.Lines.Count + 1);
    end;
  end;
end;

//==============================================================
function CdRunner.clone: CEnv;
begin
  result := CdRunner.create;
end;

procedure CdRunner.echo(const s: fun.str);
begin
  ret := ret + s;
end;

procedure CdRunner.trace(n: CNode);
  
  procedure DoEvents(needSleep: boolean = false);
  begin
    Application.ProcessMessages;
    if needSleep then
    begin
      Sleep(1);
    end;
  end;
  
begin
  if (n is CFun) or not (n is CRune) then exit;
  inherited trace(n);
  DoEvents;
  
  with fIDE do
  begin
    if not IsRunning then raise Exception.create('[Stopped]');
  
    if Files.isBreakPoint(CRune(n)) then IsBreaked := true
    else if DebugMode = dmInto      then IsBreaked := true;
  
    if IsBreaked then
    begin
      Files.ActiveFile(CRune(n));
      ActiveEdit.Invalidate;
      Output(ret, 64*1024);
  
      while IsBreaked do DoEvents(true);
      if lastOver = nil then
      begin
        if DebugMode in [dmOver, dmMore] then
          lastOver := n
        else if DebugMode = dmOut then
          lastOver := CVar.findOwner(n)
        ;
      end;
  
      if not IsRunning then raise Exception.create('[Stopped]');
    end;
  end;
end;

procedure CdRunner.traced(n: CNode; tracing: fun.bool = false);
begin
  with fIDE do
  begin
    if (n = lastOver) and (
         (DebugMode =   dmOver) or
         (DebugMode in [dmMore, dmOut]) and not tracing
       ) then
    begin
      isBreaked := true;
      lastOver  := nil;
    end;
  end;
end;

//==============================================================
constructor TfTree.Create(AOwner: TComponent);
begin
  inherited;
  NodeDataSize := SizeOf(TfData);
  BorderStyle := bsNone;
end;

//==============================================================
constructor TfEdit.Create(AOwner: TComponent);
begin
  inherited;
  Highlighter := TFunSyntax.Create(Self);
  fFunSyntax  := Highlighter;
  fFdSyntax   := TFdSyntax.Create(Self);
  Options     := Options + [
                            eoAltSetsColumnMode,
                            eoDropFiles,
                            eoHideShowScrollBars,
                          //eoSpecialLineDefaultFg,
                            eoTabIndent,
                            eoTrimTrailingSpaces
                           ]
                         - [
                           ];
  WantTabs    := True;
  TabWidth    := 2;
  ActiveLineColor   := $e0f0f0;
  Constraints.MinWidth := 200;
  with Gutter do
  begin
    AutoSize        := True;
    BorderColor     := clSilver;
    Color           := $F4F4F4;
    Font.Color      := $888888;
    DigitCount      := 1;
    LeftOffset      := 5; //4;
    RightOffset     := 5; //6;
    ShowLineNumbers := True;
    Cursor          := crHandPoint;
  end;
  with BookMarkOptions do
  begin
    LeftMargin      :=  0; //2;
    XOffset         :=  8; //12;
  end;
  OnGutterGetText   := GutterGetText;
  OnGutterClick     := GutterClick;
  OnGutterPaint     := GutterPaint;
  SearchEngine      := TfSearch.Create(Self);
  Encoding          := seAnsi;
  BOM               := False;
  FPrevCaretY := CaretY;
  FBracketLine1 := 0;
  FBracketLine2 := 0;
  OnStatusChange := StatusChange;
  
  ShowHint          := False;
  {$IfDef NewHint}
    CustomHint      := TBalloonHint.Create(Self);
    with CustomHint do
    begin
      Delay         := 0;
      HideAfter     := 5000;
    end;
  {$Else}
    Screen.HintFont := Font;
  {$EndIf}
  
  FSearchHighlights := TList.Create;
  FSearchBookmarkLines := TList.Create;
  OnPaintTransient := EditorPaintTransient;
end;

destructor TfEdit.Destroy;
begin
  ClearSearchHighlights;
  FSearchHighlights.Free;
  FSearchBookmarkLines.Free;
  Highlighter := nil;
  fFunSyntax.Free;
  fFdSyntax.Free;
  inherited;
end;

procedure TfEdit.ClearSearchHighlights;
var
  i: Integer;
  line: Integer;
begin
  for i := 0 to FSearchHighlights.Count - 1 do
    Dispose(PHighLightRange(FSearchHighlights[i]));
  FSearchHighlights.Clear;
  
  for i := 0 to FSearchBookmarkLines.Count - 1 do
  begin
    line := Integer(FSearchBookmarkLines[i]);
    if (line >= 0) and (line <= High(fStates)) then
    begin
      fStates[line] := 0;
      InvalidateGutterLine(line);
    end;
  end;
  FSearchBookmarkLines.Clear;
  InvalidateGutter;
  Invalidate;
  if Assigned(fIDE) then fIDE.RefreshTree;
end;

function TfEdit.CountMark: Integer;
var
  i: Integer;
begin
  result := 0;
  for i := Low(fStates) to High(fStates) do
  begin
    if fStates[i] <> 0 then Inc(result);
  end;
end;

function TfEdit.DisplayName: string;
begin
  result := FileName;
  if result = '' then result := TfTab(Parent).Title;
end;

function TfEdit.DoOnSpecialLineColors(Line: Integer; var Foreground, Background: TColor): Boolean;
begin
  Result := IsBreakLine(Line);
  if Result then Background := clRed;
end;

procedure TfEdit.EditorPaintTransient(Sender: TObject; Canvas: TCanvas; TransientType: TTransientType);
  
  procedure DrawSymSBezier(Canvas: TCanvas; P0, P3: TPoint; maxOffset: Integer = 40; minOffset: Integer = 10);
  var
    mx, my, dx, dy, len, t, offset: Double;
    ux, uy, vx, vy, yy: Double;
    pts, revPts: array[0..3] of TPoint;
    i: Integer;
  begin
    dx := P3.X - P0.X;
    dy := P3.Y - P0.Y;
    len := Hypot(dx, dy);
    if len < 1 then Exit;
  
    ux := dx / len;
    uy := dy / len;
    vx := -uy;
    vy := ux;
  
    offset := minOffset + (maxOffset - minOffset) * (1 - Exp(-len / 200));
    t := 0.56;
  
    mx := (P0.X + P3.X) / 2;
    my := (P0.Y + P3.Y) / 2;
  
    pts[0] := P0;
    pts[3] := P3;
  
    yy := 1;
    if Abs(dy) < 1e-5 then yy := -0.5;
    pts[1].X := Round(mx - ux * (t * len) + vx * offset * abs(yy));
    pts[1].Y := Round(my - uy * (t * len) + vy * offset * abs(yy));
    pts[2].X := Round(mx + ux * (t * len) - vx * offset * yy);
    pts[2].Y := Round(my + uy * (t * len) - vy * offset * yy);
  
    Canvas.PolyBezier(pts);
    for i := 0 to 3 do
      revPts[i] := pts[3 - i];
    Canvas.PolyBezier(revPts);
  end;

  procedure DrawBracketBox(const p: TBufferCoord);
  var
    pt: TPoint;
  begin
    pt := RowColumnToPixels(BufferToDisplayPos(p));
    Canvas.Rectangle(pt.X, pt.Y, pt.X + CharWidth - 1, pt.Y + LineHeight - 1);
  end;

  var
    i: Integer;
    pRange: PHighLightRange;
    ptStart, ptEnd: TPoint;
    dispStart, dispEnd: TDisplayCoord;
    lineHeight: Integer;
    match: TBufferCoord;

begin
  if TransientType <> ttAfter then Exit;

  // Bracket feedback: box the bracket under the caret and its partner (blue),
  // or just the unmatched caret bracket (red). Independent of search marks.
  if BracketMatch(match) then
  begin
    Canvas.Pen.Width := 1;
    Canvas.Pen.Style := psSolid;
    Canvas.Brush.Style := bsClear;
    if match.Line > 0 then
    begin
      Canvas.Pen.Color := clBlue;
      DrawBracketBox(CaretXY);
      DrawBracketBox(match);
    end
    else
    begin
      Canvas.Pen.Color := clRed;
      DrawBracketBox(CaretXY);
    end;
    Canvas.Brush.Style := bsSolid;
  end;

  if FSearchHighlights.Count = 0 then Exit;
  
  lineHeight := Self.LineHeight;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := $0080FF;
  Canvas.Pen.Style := psDot;
  
  for i := 0 to FSearchHighlights.Count - 1 do
  begin
    pRange := FSearchHighlights[i];
    dispStart := BufferToDisplayPos(pRange.StartPt);
    dispEnd   := BufferToDisplayPos(pRange.EndPt);
    ptStart := RowColumnToPixels(dispStart);
    ptEnd   := RowColumnToPixels(dispEnd);
  
    ptStart.Y := ptStart.Y + lineHeight * 2 div 3;
    ptEnd.Y   := ptEnd.Y   + lineHeight * 2 div 3;
    DrawSymSBezier(Canvas, ptStart, ptEnd);
  end;
  Canvas.Pen.Style := psSolid;
end;

procedure TfEdit.GutterClick(Sender: TObject; Button: TMouseButton; X, Y, Line: Integer; Mark: TSynEditMark);
begin
  Y := imgBookmark;
  if (BookMarkOptions <> nil) and (X > BookMarkOptions.LeftMargin+16) then
    Y := imgBreakPoint;
  
  ToggleMark(Line, Y);
end;

procedure TfEdit.GutterGetText(Sender: TObject; aLine: Integer; var aText: UnicodeString);
begin
  if (aLine = 1) or (aLine = Lines.Count) or
     (aLine = CaretY) or (aLine mod 10 = 0) then
  else
  begin
    if IsCodeLine(aLine) then
    begin
      if (aLine mod 5 = 0) then
        aText := '='
      else
        aText := WideChar($25CB) //25CB
      ;
    end
    else
    begin
      if (aLine mod 5 = 0) then
        aText := '-'
      else
        aText := WideChar($00B7) //00B7
      ;
    end;
  end;
end;

procedure TfEdit.GutterPaint(Sender: TObject; aLine: Integer; X, Y: Integer);
var
  i: Integer;
begin
  if BookMarkOptions = nil then Exit;
  if ImageList = nil then Exit;
  
  with BookMarkOptions do
  begin
    i := -1;
    if IsBreakLine(aLine) then
      i := ImgBreakLine
    else if IsBreakPoint(aLine) then
    begin
      if IsCodeLine(aLine) then
        i := ImgBreakPoint
      else
        i := ImgBreakFake
      ;
    end
    else if IsBookmark(aLine) then
      i := ImgBookmark
    ;
    if i <> -1 then ImageList.Draw(Canvas, X + LeftMargin, Y, i);
  end;
  
  if aLine = CaretY then
  begin
    with Canvas do
    begin
      i := fGutterWidth -1;
      Pen.Color := clRed;
      Pen.Width := 2;
      MoveTo(i,  Y);
      LineTo(i,  Y+LineHeight-1);
    end;
  end;
end;

function TfEdit.IsBookmark(Line: Integer): Boolean;
begin
  Result := False;
  if Line < High(fStates) then Result := fStates[Line] = imgBookmark;
end;

function TfEdit.IsBreakLine(Line: Integer): Boolean;
begin
  //todo
  //Result := False;
  //Result := Line = CaretY; //test
  with fIDE do
  Result := IsRunning and IsBreaked and
            (CRune(_ENV.LastNode).row = Line) and
            (f <> nil) and
            //f.sameCode(CRune(_ENV.LastNode))
            f.hasCode(line) // multi codes in a line !
            and SameText(CModu(_ENV.LastNode.root).fileName, FileName)
         ;
end;

function TfEdit.IsBreakPoint(Line: Integer): Boolean;
begin
  Result := False;
  if Line < High(fStates) then Result := fStates[Line] = ImgBreakPoint;
end;

function TfEdit.IsCodeLine(Line: Integer): Boolean;
begin
  Result := False;
  if fIDE.IsRunning then Result := (f <> nil) and f.hasCode(line);
end;

procedure TfEdit.Load;
const
  cps: array[TSynEncoding] of fun.word = (65001, 1200, 1201, 0);
var
  ob: Boolean;
  ext: string;
begin
  Highlighter.Enabled := True;
  ext := LowerCase(ExtractFileExt(FileName));
  if ext = '.fun' then
    Highlighter := fFunSyntax
  else if ext = '.fd' then
    Highlighter := fFdSyntax
  else
    Highlighter.Enabled := False
  ;
  
  Lines.BeginUpdate;
  ob := WordWrap;
  WordWrap := False; // So fast !
  try
    try
      Encoding := GetEncoding(FileName, BOM);
      Lines.Text := CIO.Load(FileName, cps[Encoding]);
    except
    end;
    if Lines.Count < 1000 then WordWrap := ob;
  finally
    Lines.EndUpdate;
  end;
  Modified := False;
  LastTime := GetTime(FileName);
end;

procedure TfEdit.ReLoad(const AEncoding: TSynEncoding);
const
  cps: array[TSynEncoding] of fun.word = (65001, 1200, 1201, 0);
var
  ob: Boolean;
begin
  Encoding := AEncoding;
  BOM      := False;
  // An unsaved buffer has no bytes on disk to re-read; just retarget the
  // encoding used when it is eventually saved.
  if FileName = '' then
  begin
    Modified := True;
    exit;
  end;
  ob := WordWrap;
  WordWrap := False;
  Lines.BeginUpdate;
  try
    try
      Lines.Text := CIO.Load(FileName, cps[AEncoding]);
    except
    end;
    if Lines.Count < 1000 then WordWrap := ob;
  finally
    Lines.EndUpdate;
  end;
  Modified := False;
  LastTime := GetTime(FileName);
end;

procedure TfEdit.Save;
var
  lb: UnicodeString;
begin
  // Lines.Text always uses sLineBreak (CRLF on Windows), so build the text
  // with the line break that matches the buffer's file format instead.
  case TSynEditStringList(Lines).FileFormat of
    sffUnix:    lb := #10;      // LF
    sffMac:     lb := #13;      // CR
    sffUnicode: lb := #$2028;   // LINE SEPARATOR
  else
    lb := #13#10;               // CRLF (sffDos)
  end;
  SaveToFile(TSynEditStringList(Lines).GetSeparatedText(lb), FileName, Encoding, BOM);
  Modified := False;
  LastTime := GetTime(FileName);
end;

procedure TfEdit.SetSearchHighlights(AList: TList);
var
  i: Integer;
  pSrc, pDest: PHighLightRange;
  line: Integer;
begin
  ClearSearchHighlights;
  
  for i := 0 to AList.Count - 1 do
  begin
    pSrc := AList[i];
    New(pDest);
    pDest^ := pSrc^;
    FSearchHighlights.Add(pDest);
  
    line := pSrc.StartPt.Line;
    if line > High(fStates) then SetLength(fStates, line + 1);
    if fStates[line] = 0 then
    begin
      fStates[line] := ImgBookmark;
      InvalidateGutterLine(line);
      FSearchBookmarkLines.Add(Pointer(line));
    end;
  end;
  
  InvalidateGutter;
  Invalidate;
  if Assigned(fIDE) then fIDE.RefreshTree;
end;

procedure TfEdit.StatusChange(Sender: TObject; Changes: TSynStatusChanges);
var
  Match: TBufferCoord;
begin
  if (scCaretX in Changes) or (scCaretY in Changes) then
  begin
    // Erase the previous bracket boxes (the match may sit on another line),
    // then remember the new ones so the next caret move can erase these too.
    if FBracketLine1 > 0 then InvalidateLine(FBracketLine1);
    if FBracketLine2 > 0 then InvalidateLine(FBracketLine2);
    FBracketLine1 := 0;
    FBracketLine2 := 0;
    if BracketMatch(Match) then
    begin
      FBracketLine1 := CaretY;
      FBracketLine2 := Match.Line; // 0 when the bracket is unmatched
    end;
    if FBracketLine1 > 0 then InvalidateLine(FBracketLine1);
    if FBracketLine2 > 0 then InvalidateLine(FBracketLine2);
  end;

  if scCaretY in Changes then
  begin
    if FPrevCaretY <> CaretY then
    begin
      InvalidateGutterLine(FPrevCaretY);
      InvalidateGutterLine(CaretY);
      FPrevCaretY := CaretY;
    end;
  end;
end;

// True when the caret sits on one of ()[]{}; Match receives the paired
// bracket position (Char/Line = 0 when unmatched). Comment/string contents are
// skipped by SynEdit's own GetMatchingBracketEx, so it needs no extra logic.
function TfEdit.BracketMatch(out Match: TBufferCoord): Boolean;
var
  s: UnicodeString;
  ch: WideChar;
begin
  Match.Char := 0;
  Match.Line := 0;
  Result := False;
  if (CaretY < 1) or (CaretY > Lines.Count) then Exit;
  s := Lines[CaretY - 1];
  if (CaretX < 1) or (CaretX > Length(s)) then Exit;
  ch := s[CaretX];
  if not (ch in ['(', ')', '[', ']', '{', '}']) then Exit;
  Result := True;
  Match := GetMatchingBracketEx(CaretXY);
end;

procedure TfEdit.ToggleAllMarks(Mark: Integer);
var
  i: Integer;
begin
  for i := 0 to Length(fStates) -1 do
  begin
    if (mark = 0) or (fStates[i] = mark) then
      fStates[i] := 0;
    InvalidateGutterLine(i);
  end;
end;

procedure TfEdit.ToggleMark(Line, Mark: Integer);
var
  len: Integer;
begin
  if Line = -1 then Line := CaretY;
  len := Lines.Count + 2;
  if Length(fStates) < len then SetLength(fStates, len);
  if (fStates[Line] = 0) or (fStates[Line] <> mark) then
  begin
    fStates[Line] := mark;
    if FileName = '' then
      fIDE.AddFile(TfTab(Parent).Title, Self);
  end
  else
    fStates[Line] := 0
  ;
  InvalidateGutterLine(Line);
  
  fIDE.RefreshTree;
end;

//==============================================================
constructor TfTab.Create(AOwner: TComponent);
begin
  inherited;
  FEdit := TfEdit.Create(Self);
  FEdit.Align       := alClient;
  FEdit.BorderStyle := bsNone;
  FEdit.Parent      := Self;
end;

destructor TfTab.Destroy;
begin
  fIDE.RemFile(Edit.DisplayName);
  inherited Destroy;
end;

function TfTab.GetFileName: string;
begin
  Result := FEdit.FileName;
end;

function TfTab.GetTitle: string;
begin
  result := StringReplace(Caption, ' ' + WideChar($00D7), '', []);
end;

procedure TfTab.Load;
begin
  FEdit.Load;
end;

procedure TfTab.Save;
begin
  FEdit.Save;
end;

procedure TfTab.SetFileName(const Value: string);
begin
  fIDE.RemFile(Edit.DisplayName);
  FEdit.FileName := Value;
  Title          := ExtractFileName(Value);
end;

procedure TfTab.SetTitle(const Value: string);
begin
  Caption := Value + ' ' + WideChar($00D7); //00D7
end;

//==============================================================
constructor TfSearch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fRegex := CPcre.Create;
  fRegex.Options := [preMultiLine, preSingleLine];
  fPositions := TList.Create;
  fLengths := TList.Create;
end;

destructor TfSearch.Destroy;
begin
  inherited;
  fRegex.Free;
  fPositions.Free;
  fLengths.Free;
end;

function TfSearch.FindAll(const NewText: UnicodeString): Integer;
  
  function Utf8ToCharIndex(const S: UnicodeString; ByteOffset: Integer): Integer;
  var
    UTF8: UTF8String;
    i, Count: Integer;
  begin
    UTF8 := UTF8Encode(S);
    Count := 0;
    for i := 1 to ByteOffset do
    begin
      if i > Length(UTF8) then Break;
      if (Ord(UTF8[i]) and $C0) <> $80 then
        Inc(Count);
    end;
    Result := Count;
  end;
  
  procedure AddResult(const aPos, aLength: Integer);
  var
    CharStart, CharLen: Integer;
  begin
    CharStart := Utf8ToCharIndex(NewText, aPos);
    CharLen   := Utf8ToCharIndex(NewText, aPos + aLength) - CharStart;
    fPositions.Add(Pointer(CharStart));
    fLengths.Add(Pointer(CharLen));
  end;
  
begin
  fPositions.Clear;
  fLengths.Clear;
  fRegex.Subject := NewText;
  if fRegex.Match then
  begin
    AddResult(fRegex.MatchedOffset, fRegex.MatchedLength);
    Result := 1;
    while fRegex.Match do
    begin
      AddResult(fRegex.MatchedOffset, fRegex.MatchedLength);
      Inc(Result);
    end;
  end
  else
    Result := 0;
end;

function TfSearch.GetLength(Index: Integer): Integer;
begin
  Result := Integer(fLengths[Index]);
end;

function TfSearch.GetPattern: UnicodeString;
begin
  Result := fRegex.Pattern;
end;

function TfSearch.GetResult(Index: Integer): Integer;
begin
  Result := Integer(fPositions[Index]);
end;

function TfSearch.GetResultCount: Integer;
begin
  Result := fPositions.Count;
end;

function TfSearch.Replace(const aOccurrence, aReplacement: UnicodeString): UnicodeString;
begin
  fRegex.Subject := aOccurrence;
  fRegex.Replacement := aReplacement;
  fRegex.ReplaceAll;
  Result := fRegex.Subject;
end;

procedure TfSearch.SetOptions(const Value: TSynSearchOptions);
begin
  if ssoMatchCase in Value then
    fRegex.Options := fRegex.Options - [preCaseLess]
  else
    fRegex.Options := fRegex.Options + [preCaseLess]
  ;
end;

procedure TfSearch.SetPattern(const Value: UnicodeString);
begin
  fRegex.Pattern := Value;
end;

//==============================================================
function TfFile.hasCode(line: fun.int): Boolean;
begin
  result := (High(fCodes) >= line) and (fCodes[line] <> nil);
end;

function TfFile.sameCode(n: CRune): Boolean;
begin
  result := (High(fCodes) >= n.row) and (fCodes[n.row] = n);
end;

procedure TfFile.SetEdit(Value: TfEdit);
begin
  if fEdit <> nil then fEdit.f := nil;
  fEdit := Value;
  if fEdit <> nil then fEdit.f := self;
end;

//==============================================================
constructor TfFiles.Create;
begin
  inherited Create;
  Files := TList.create;
end;

destructor TfFiles.Destroy;
var
  i: Integer;
begin
  for i := 0 to count-1 do
  begin
    TfFile(Files[i]).Free
  end;
  Files.Free;
  inherited Destroy;
end;

function TfFiles.ActiveFile(n: CRune): TfFile;
var
  p: CModu;
begin
  with fIDE do
  begin
    p := CModu(n.root);
    OpenTab(p.fileName);
    if (f = nil) or (High(f.fCodes) < n.row) or (f.fCodes[n.row] <> n) then
    begin
      f := Find(p.fileName);
      f.Edit := ActiveEdit;
    end;
    f.Edit.GotoLineAndCenter(n.row);
  end;
  result := f;
end;

function TfFiles.Add(const fn: string; edit: TfEdit; dontCreate: Boolean = False): TfFile;
var
  f: TfFile;
begin
  f := Find(fn);
  if (f = nil) and not dontCreate then
  begin
    f := TfFile.create;
    f.Name := fn;
    Files.add(f);
  end;
  if f <> nil then f.Edit := edit;
  Result := f;
end;

function TfFiles.Count: Integer;
begin
  Result := Files.count;
end;

function TfFiles.CountVisible: Integer;
var
  i: Integer;
begin
  Result := Count();
  for i := Result-1 downto 0 do
  begin
    if FS[i].Edit = nil then Dec(Result);
  end;
end;

function TfFiles.Find(const fn: string; isAdd: boolean = false): TfFile;
var
  I: Integer;
begin
  result := nil;
  for i := 0 to count-1 do
  begin
    if SameText(FS[i].Name, fn) then
    begin
      result := Files[i];
      exit;
    end;
  end;
  if (result = nil) and isAdd then result := Add(fn, nil);
end;

function TfFiles.GetFS(Index: Integer): TfFile;
begin
  result := nil;
  if Index < count then result := TfFile(Files[Index]);
end;

function TfFiles.IsBreakpoint(n: CRune): Boolean;
var
  i, k: Integer;
begin
  Result := False;
  k := n.row;
  for i := Count-1 downto 0 do
  begin
    if (FS[i].Edit <> nil) and FS[i].Edit.IsBreakPoint(k) then
    begin
      if FS[i].sameCode(n) then
      begin
        Result := true;
        exit;
      end;
    end;
  end;
end;

function TfFiles.Visible(i: Integer): Boolean;
begin
  result := false;
  if i < count then result := FS[i].Edit <> nil;
end;

//==============================================================
procedure TfIDE.aAboutExecute(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://funlang.org/', nil, nil, 1);
end;

procedure TfIDE.aBreakPointExecute(Sender: TObject);
begin
  ActiveEdit.ToggleMark(-1, ImgBreakPoint);
end;

procedure TfIDE.aClearAllExecute(Sender: TObject);
begin
  DoClearAll(0);
end;

procedure TfIDE.aClearBookmarksExecute(Sender: TObject);
begin
  DoClearAll(ImgBookmark);
end;

procedure TfIDE.aClearBreakpointsExecute(Sender: TObject);
begin
  DoClearAll(ImgBreakPoint);
end;

procedure TfIDE.aClearExecute(Sender: TObject);
begin
  if vtNodes.FocusedNode <> nil then
  begin
    ClearTree(vtNodes.FocusedNode);
  end;
end;

procedure TfIDE.aCloseAllExecute(Sender: TObject);
var
  i: Integer;
begin
  try
    for i := tabs.PageCount - 1 downto 0 do
    begin
      tabs.ActivePageIndex := i;
      aCloseExecute(nil)
    end;
  except
  end;
end;

procedure TfIDE.aCloseExecute(Sender: TObject);
var
  i: Integer;
  p: TTabSheet;
begin
  if ActiveEdit <> nil then with ActiveEdit do
  begin
    if Modified then
    begin
      case MessageBox(0, PChar('[' +DisplayName+ '] was modified, save changes now?'), 'Confirmation', MB_YESNOCANCEL or MB_ICONQUESTION or MB_DEFBUTTON3) of
        IDYES:
        begin
          aSaveExecute(Sender);
          if Modified then exit;
        end;
        IDCANCEL: if Sender = nil then raise Exception.Create('action aborted') else exit;
      end;
    end;
  end;
  
  p := tabs.ActivePage;
  i := p.PageIndex;
  if (i > 0) and (i >= tabs.PageCount - 1) then
    p.PageIndex := i - 1
  ;
  p.Free;
end;

procedure TfIDE.aCloseOthersExecute(Sender: TObject);
var
  p: TTabSheet;
begin
  p := tabs.ActivePage;
  p.PageControl := nil;
  aCloseAllExecute(Sender);
  p.PageControl := tabs;
end;

procedure TfIDE.aCollapseExecute(Sender: TObject);
begin
  vtNodes.FullCollapse;
end;

procedure TfIDE.aCopyExecute(Sender: TObject);
begin
  ActiveEdit.CopyToClipboard;
end;

function TfIDE.ActiveEdit: TfEdit;
begin
  result := nil;
  if tabs.ActivePage = nil then exit;
  result := TfTab(tabs.ActivePage).fEdit;
end;

procedure TfIDE.aCutExecute(Sender: TObject);
begin
  ActiveEdit.CutToClipboard;
end;

procedure TfIDE.AddFile(const fn: string; edit: TfEdit = nil);
begin
  Files.add(fn, edit);
  RefreshTree;
end;

procedure TfIDE.AddLog(const f: string);
var
  i: Integer;
begin
  AddFile(f, ActiveEdit);
  
  i := fLogs.IndexOf(f);
  if (fLogs.Count = 0) or (i <> fLogs.Count - 1) then
  begin
    if i >= 0 then fLogs.Delete(i);
    fLogs.Add(f);
    fLogs.SaveToFile(LogFile);
    LoadLogs();
  end;
end;

procedure TfIDE.aExpandExecute(Sender: TObject);
begin
  vtNodes.FullExpand;
end;

procedure TfIDE.aFindAllExecute(Sender: TObject);
  
  function CharIndexToRowCol(const Text: string; Index: Integer): TBufferCoord;
  var
    row, col, i: Integer;
  begin
    row := 1;
    col := 1;
    for i := 1 to Index - 1 do
    begin
      if i > Length(Text) then Break;
      if Text[i] = #10 then
      begin
        Inc(row);
        col := 1;
      end
      else if Text[i] <> #13 then
        Inc(col);
    end;
    Result.Line := row;
    Result.Char := col;
  end;
  
  var
    FullText: string;
    Options: TSynSearchOptions;
    Pattern: string;
    n, i: Integer;
    PStart, PEnd: TBufferCoord;
    pRange: PHighLightRange;
    TempList: TList;
  
begin
  if ActiveEdit = nil then Exit;
  if mmoFind.Text = '' then
  begin
    ActiveEdit.ClearSearchHighlights;
    ActiveEdit.SelLength := 0;
    Exit;
  end;
  
  Options := GetSearchOptions([ssoEntireScope]);
  Pattern := mmoFind.Text;
  if not aFindRegex.Checked then
    Pattern := '\Q' + Pattern + '\E';
  if aFindWholeWord.Checked then
    Pattern := '\b' + Pattern + '\b';
  
  ActiveEdit.SearchEngine.Options := Options;
  ActiveEdit.SearchEngine.Pattern := Pattern;
  
  FullText := ActiveEdit.Lines.Text;
  n := ActiveEdit.SearchEngine.FindAll(FullText);
  
  TempList := TList.Create;
  try
    for i := 0 to n - 1 do
    begin
      New(pRange);
      pRange.StartPt := CharIndexToRowCol(FullText, ActiveEdit.SearchEngine.Results[i]);
      pRange.EndPt   := CharIndexToRowCol(FullText, ActiveEdit.SearchEngine.Results[i] +
                                          ActiveEdit.SearchEngine.Lengths[i]);
      TempList.Add(pRange);
    end;
  
    ActiveEdit.SetSearchHighlights(TempList);
  finally
    for i := 0 to TempList.Count - 1 do
      Dispose(PHighLightRange(TempList[i]));
    TempList.Free;
  end;
  
  if n > 0 then
  begin
    PStart := CharIndexToRowCol(FullText, ActiveEdit.SearchEngine.Results[0] + 1);
    PEnd   := CharIndexToRowCol(FullText, ActiveEdit.SearchEngine.Results[0] + 1 +
                                ActiveEdit.SearchEngine.Lengths[0]);
    ActiveEdit.BlockBegin := PStart;
    ActiveEdit.BlockEnd   := PEnd;
    ActiveEdit.CaretXY    := PStart;
    ActiveEdit.EnsureCursorPosVisible;
  end;
  
  ActiveEdit.Invalidate;
  prc.Height := pr.ClientHeight div 2;  // tree control
  RefreshTree;
  LocateActiveFileInTree;
end;

procedure TfIDE.aFindExecute(Sender: TObject);
begin
  mmoFind.SetFocus;
  mmoFind.Text := ActiveEdit.SelText;
end;

procedure TfIDE.aFindMatchCaseExecute(Sender: TObject);
begin
  // No Action
end;

procedure TfIDE.aFindNextExecute(Sender: TObject);
begin
  Search();
end;

procedure TfIDE.aFindPrevExecute(Sender: TObject);
begin
  // No Action
end;

procedure TfIDE.aFindRegexExecute(Sender: TObject);
begin
  // No Action
end;

procedure TfIDE.aFindSelectedExecute(Sender: TObject);
begin
  // No Action
end;

procedure TfIDE.aFindWholeWordExecute(Sender: TObject);
begin
  // No Action
end;

procedure TfIDE.aHelpExecute(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://funlang.org/man.htm', nil, nil, 1);
end;

procedure TfIDE.aNewExecute(Sender: TObject);
begin
  NewTab;
end;

procedure TfIDE.aOpenExecute(Sender: TObject);
var
  i: Integer;
  s: string;
begin
  if Sender is TMenuItem then
  begin
    s := TMenuItem(Sender).Caption;
    Delete(s, 1, 4);
    OpenTab(s);
    exit;
  end;
  
  with dlgOpen do
  begin
    if ActiveEdit <> nil then
    begin
      if ActiveEdit.FileName <> '' then
        InitialDir := ExtractFilePath(ActiveEdit.FileName);;
    end;
  
    if Execute(Self.Handle) then
    begin
      for i := 0 to Files.Count - 1 do
      begin
        OpenTab(Files[i]);
      end;
    end;
  end;
end;

procedure TfIDE.aOptionsExecute(Sender: TObject);
var
  i: Integer;
begin
  if fOptions = nil then fOptions := TSynEditorOptionsContainer.Create(Self);
  fOptions.Assign(ActiveEdit);
  
  if dlgOptions = nil then dlgOptions := TSynEditOptionsDialog.Create(Self);
  with dlgOptions do
  if Execute(fOptions) then
  begin
    for i := 0 to tabs.PageCount - 1 do
      fOptions.AssignTo(TfTab(tabs.Pages[i]).fEdit);
    ;
    if fInis = nil then fInis := TStringList.Create;
    fInis.Values['Font-Name'] := fOptions.Font.Name;
    fInis.Values['Font-Size'] := IntToStr(fOptions.Font.Size);
    fInis.Values['RightEdge'] := IntToStr(fOptions.RightEdge);
    fInis.Values['ExtraLineSpacing'] := IntToStr(fOptions.ExtraLineSpacing);
    fInis.SaveToFile(IniFile);
  end;
end;

procedure TfIDE.aPasteExecute(Sender: TObject);
begin
  ActiveEdit.PasteFromClipboard;
end;

procedure TfIDE.aPauseExecute(Sender: TObject);
begin
  IsBreaked := True;
  UpdateStatus;
end;

procedure TfIDE.appeHint(Sender: TObject);
begin
  stats.Panels[4].Text := Application.Hint;
end;

procedure TfIDE.appeIdle(Sender: TObject; var Done: Boolean);
begin
  UpdateStatus;
  Done := True;
end;

procedure TfIDE.aRedoExecute(Sender: TObject);
begin
  ActiveEdit.Redo;
end;

procedure TfIDE.aReplaceAllExecute(Sender: TObject);
begin
  Search([ssoReplaceAll, ssoEntireScope]);
end;

procedure TfIDE.aReplaceExecute(Sender: TObject);
begin
  Search([ssoReplace]);
end;

procedure TfIDE.aRunExecute(Sender: TObject);
begin
  //if ActiveEdit.FileName = '' then exit;
  //ShellExecute(0, nil, PChar(ActiveEdit.FileName), nil, nil, 1);
  
  IsBreaked := False;
  DoRun;
end;

procedure TfIDE.aRunOutExecute(Sender: TObject);
begin
  if ActiveEdit.FileName = '' then exit;
  ShellExecute(0, nil, 'Cmd.exe', PChar('/K ' + IdePath() + 'Fun.exe "'  + ActiveEdit.FileName + '" -v'), nil, 1);
  //ShellExecute(0, nil, PChar(ActiveEdit.FileName), nil, nil, 1);
end;

procedure TfIDE.aRunUniCNExecute(Sender: TObject);
begin
  if ActiveEdit.FileName = '' then exit;
  ShellExecute(0, nil, 'Cmd.exe', PChar('/K ' + IdePath() + 'Funu.exe "' + ActiveEdit.FileName + '" -v -key:key_cn.ini'), nil, 1);
  //ShellExecute(0, 'OpenCN', PChar(ActiveEdit.FileName), nil, nil, 1);
end;

procedure TfIDE.aRunUniExecute(Sender: TObject);
begin
  if ActiveEdit.FileName = '' then exit;
  ShellExecute(0, nil, 'Cmd.exe', PChar('/K ' + IdePath() + 'Funu.exe "' + ActiveEdit.FileName + '" -v'), nil, 1);
  //ShellExecute(0, 'OpenU', PChar(ActiveEdit.FileName), nil, nil, 1);
end;

procedure TfIDE.aSaveAsExecute(Sender: TObject);
begin
  with dlgSave do
  begin
    FileName := ActiveEdit.FileName;
    if FileName <> '' then InitialDir := ExtractFilePath(FileName);
    if Execute(Self.Handle) then
    begin
      TfTab(tabs.ActivePage).FileName := FileName;
      aSaveExecute(Sender);
    end;
  end;
end;

procedure TfIDE.aSaveExecute(Sender: TObject);
begin
  if ActiveEdit.FileName = '' then
    aSaveAsExecute(Sender)
  else
  begin
    ActiveEdit.Save();
    AddLog(ActiveEdit.FileName);
  end;
end;

procedure TfIDE.aSpecCharExecute(Sender: TObject);
begin
  with ActiveEdit, aSpecChar do
  begin
    if Checked then
      Options := Options + [eoShowSpecialChars]
    else
      Options := Options - [eoShowSpecialChars]
    ;
  end;
end;

procedure TfIDE.aStepIntoExecute(Sender: TObject);
begin
  DoStep(dmInto);
end;

procedure TfIDE.aStepMoreExecute(Sender: TObject);
begin
  DoStep(dmMore);
end;

procedure TfIDE.aStepOutExecute(Sender: TObject);
begin
  DoStep(dmOut);
end;

procedure TfIDE.aStepOverExecute(Sender: TObject);
begin
  DoStep(dmOver);
end;

procedure TfIDE.aStopExecute(Sender: TObject);
begin
  IsBreaked := False;
  IsRunning := False;
end;

procedure TfIDE.aUndoExecute(Sender: TObject);
begin
  ActiveEdit.Undo;
end;

procedure TfIDE.aWordWrapExecute(Sender: TObject);
begin
  ActiveEdit.WordWrap := aWordWrap.Checked;
end;

function TfIDE.CheckExists(const f: string): Boolean;
var
  i: Integer;
begin
  result := False;
  for i := 0 to tabs.PageCount - 1 do
  begin
    if SameText(f, TfTab(tabs.Pages[i]).FileName) then
    begin
      result := true;
      if tabs.ActivePageIndex <> i then tabs.ActivePageIndex := i;
      exit;
    end;
  end;
end;

procedure TfIDE.ClearTree(node: PVirtualNode; mark: Integer = 0);
var
  data, pdata: PfData;
  n: PVirtualNode;
begin
  // all marks in file(s)
  if (node = nil) or (vtNodes.GetNodeLevel(node) = 0) then
  begin
    n := vtNodes.GetFirstChild(node);
    if n <> nil then
    begin
      vtNodes.BeginUpdate;
      try
        if node <> nil then
        begin
          data := vtNodes.GetNodeData(node);
          data.Edit.ToggleAllMarks(mark);
        end
        else while n <> nil do
        begin
          ClearTree(n, mark);
          n := n.NextSibling;
        end;
      finally
        vtNodes.EndUpdate;
      end;
      RefreshTree;
    end;
  end
  else // a mark
  begin
    data := vtNodes.GetNodeData(node);
    if (mark = 0) or (mark = data.Image) then
    begin
      pdata := vtNodes.GetNodeData(node.Parent);
      pdata.Edit.ToggleMark(data.Index, data.Image);
    end;
  end;
end;

procedure TfIDE.DoClearAll(mark: Integer);
var
  node: PVirtualNode;
begin
  node := vtNodes.FocusedNode;
  if node <> nil then
  begin
    if vtNodes.GetNodeLevel(node) = 0 then
      node := nil
    else
      node := node.Parent
    ;
  end;
  ClearTree(node, mark);
end;

function TfIDE.DoDebugCmd(const s: string): string;
begin
  result := s;
  delete(result, 1, 1);
  result := trim(result);
  try
    result := EvalExpr(result);
  except
    result := result + _NotFound;
  end;
end;

procedure TfIDE.DoRun;
begin
  if IsRunning then
  begin
    DoStep(dmGo);
    exit;
  end;
  
  if ActiveEdit.Lines.Text = '' then exit;
  try
    FreeAndNil(root);
    FreeAndNil(_ENV);
    root := CdParser.Parse(ActiveEdit.Lines.Text, CdParser, ActiveEdit.FileName);
    _ENV := CdRunner.create;
  
    IsRunning := true;
    UpdateStatus;
    //ActiveEdit.InvalidateGutter;
    ActiveEdit.Invalidate;
    //RefreshTree;
  
    uiform.init;
    root.run(_ENV);
    Output(CdRunner(_ENV).ret);
  except
    on e: exception do
    begin
      try
        Output(CdRunner(_ENV).ret + LastErrorPos + e.Message, 64*1024);
      except
        Output(e.Message);
      end;
    end;
  end;
  IsRunning := false;
  DebugMode := dmGo;
  //ActiveEdit.InvalidateGutter;
  ActiveEdit.Invalidate;
  RefreshTree;
  //mmoFind.SetFocus;
  //mmoReplace.SetFocus; // ActiveEdit miss Caret Cursor
end;

procedure TfIDE.DoStep(dm: TfDebugMode);
begin
  DebugMode := dm;
  if IsRunning then
  begin
    IsBreaked := False;
    //UpdateStatus;
    //ActiveEdit.Invalidate;
  end
  else
  begin
    IsBreaked := True;
    DoRun;
  end;
end;

procedure TfIDE.DropFiles(Sender: TObject; X, Y: Integer; Files: TUnicodeStrings);
var
  i: Integer;
begin
  for i := 0 to Files.Count - 1 do
  begin
    OpenTab(Files[i]);
  end;
end;

function TfIDE.EvalExpr(const s: string): string;
var
  tree: CRun;
  e: CExp;
  v: CValue;
begin
  Result := s + _NotFound;
  if (_ENV = nil) or (_ENV.lastNode = nil) then exit;
  tree := nil;
  e := CParser.ParseExp(s, _ENV.lastNode, tree);
  try
    if e = nil then exit;
    e.calcValue(_ENV);
    if e.asObj is CSet then
    begin
      _ENV.call(e, '@toJson', nil, @v);
      Result := fun.str(v);
    end
    else
      Result := e.asStr
    ;
  finally
    if tree <> nil then FreeAndNil(tree);
  end;
end;

procedure TfIDE.Evaluate;
var
  P: TPoint;
  B: TBufferCoord;
begin
  if isRunning and isBreaked then
  with ActiveEdit do
  begin
    lastWord := SysUtils.Trim(SelText);
    if lastWord = '' then lastWord := WordAtMouse;
    if lastWord <> '' then
    try
      Hint := lastWord + ' = ' + EvalExpr(lastWord);
      GetCursorPos(P);
  
    {$IfDef NewHint}
      ShowHint := False;
      with CustomHint do
      begin
        if Images = nil then Images := ImageList;
        Title       := lastWord;
        Description := Hint;
        ImageIndex  := aHelp.ImageIndex;
        ShowHint();
      end;
    {$Else}
      if GetPositionOfMouse(B) then
      begin
        B := WordStartEx(B);
        Inc(B.Line);
        P := ClientToScreen(RowColumnToPixels(BufferToDisplayPos(B)));
        Dec(P.X, 3);
        Dec(P.Y, 6);
      end;
      Application.ActivateHint(P);
      Application.Hint := Hint;
      Hint := '';
    {$EndIf}
    except
    end;
  end;
end;

procedure TfIDE.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  aCloseAllExecute(Sender);
  CanClose := tabs.ActivePage = nil;
end;

procedure TfIDE.FormShow(Sender: TObject);
var
  s: string;
begin
  Files := TfFiles.create;
  stats.OnClick := statsClick;
  mmoReplace.OnDblClick := mmoReplaceDblClick; // T3: jump on double click
  DragAcceptFiles(Handle, True);
  LoadLogs;
  if fInis = nil then fInis := TStringList.Create;
  if FileExists(IniFile) then fInis.LoadFromFile(IniFile);
  
  
  vtNodes := TfTree.Create(prc);
  with vtNodes do
  begin
    Parent := prc;
    Align  := alClient;
    Images := il1;
    Header.Columns.Add.Text := 'File';
    Header.Options  := [hoAutoResize, hoColumnResize, hoVisible];
    Header.Height   := 18;
    OnFocusChanged  := TreeFocusChange;
    OnGetImageIndex := TreeGetImageIndex;
    OnGetText       := TreeGetText;
    OnInitChildren  := TreeInitChildren;
    OnInitNode      := TreeInitNode;
    TreeOptions.SelectionOptions := [toFullRowSelect];
    TreeOptions.PaintOptions     := [toHideFocusRect, toShowButtons, toShowRoot, toThemeAware, toUseExplorerTheme];
  end;
  
  s := ParamStr(1);
  if (s <> '') and FileExists(s) then
    OpenTab(s)
  else
    NewTab
  ;
  
  pr.Width := Self.ClientWidth * 3 div 10;
  with mmoFind do
  begin
    Font.Size := 10;
    RightEdge := 70;
  end;
  
  with TTimer.Create(Self) do
  begin
    Interval := 1000;
    OnTimer  := UpdateStatus;
  end;
  
  fPresetFile := ParamStr(0) + '.presets';
  LoadFindPresets;
end;

function TfIDE.GetSearchOptions(so: TSynSearchOptions = []): TSynSearchOptions;
begin
  Result := so;
  if aFindPrev.Checked then Include(Result, ssoBackwards);
  if aFindMatchCase.Checked then Include(Result, ssoMatchCase);
  if aFindSelected.Checked then
  begin
    Include(Result, ssoSelectedOnly);
    Exclude(Result, ssoEntireScope);
  end
  else
    //Include(Result, ssoEntireScope)
  ;
end;

function TfIDE.IniFile: string;
begin
  result := ParamStr(0) + '.ini';
end;

procedure TfIDE.LoadFindPresets;
  
  procedure SplitPresetLine(const ALine: string; out AName, APattern: string);
  var
    p: Integer;
  begin
    p := Pos('=', ALine);
    if p = 0 then
    begin
      AName := '';
      APattern := '';
      Exit;
    end;
    AName := Trim(Copy(ALine, 1, p - 1));
    APattern := Trim(Copy(ALine, p + 1, MaxInt));
  end;
  
  var
    sl: TStringList;
    i: Integer;
    mi: TMenuItem;
    sName, sPattern, sLine: string;
  
begin
  pmFindPresets.Items.Clear;
  if not FileExists(fPresetFile) then Exit;
  
  sl := TStringList.Create;
  try
    sl.LoadFromFile(fPresetFile);
    for i := 0 to sl.Count - 1 do
    begin
      sLine := Trim(sl[i]);
      if (sLine = '') or (sLine = '-') then
      begin
        mi := TMenuItem.Create(pmFindPresets);
        mi.Caption := '-';
        pmFindPresets.Items.Add(mi);
        Continue;
      end;
  
      SplitPresetLine(sLine, sName, sPattern);
      if sName = '' then Continue;
  
      mi := TMenuItem.Create(pmFindPresets);
      mi.Caption := sName;
      mi.Hint := sPattern;
      mi.OnClick := PresetItemClick;
      pmFindPresets.Items.Add(mi);
    end;
  finally
    sl.Free;
  end;
end;

procedure TfIDE.LoadLogs;
  
  const c32   = 36;
  const ckeys = '0123456789abcdefghijklmnopqrstuvwxyz';
  var
    i, j: Integer;
    mi: TMenuItem;
    s: string;
  
begin
  if fLogs = nil then fLogs := TStringList.Create;
  if FileExists(LogFile) then fLogs.LoadFromFile(LogFile);
  
  i := 0;
  for j := fLogs.Count -1 downto 0 do
  begin
    if FileExists(fLogs[j]) and (i < c32) then
      Inc(i)
    else
      fLogs.Delete(j)
    ;
  end;
  
  fLogs.SaveToFile(LogFile);
  
  s := fLogs.Text;
  TStringList(fLogs).Sorted := true;
  pmOpen.Items.Clear;
  for i := 0 to fLogs.Count - 1 do
  begin
    mi := TMenuItem.Create(pmOpen);
    pmOpen.Items.Add(mi);
    mi.Caption := '&' + cKeys[i+1] + '. ' + fLogs[i];
    mi.OnClick := aOpenExecute;
  end;
  TStringList(fLogs).Sorted := false;
  fLogs.Text := s;
end;

procedure TfIDE.LocateActiveFileInTree;
var
  RootNode, ChildNode: PVirtualNode;
  Data: PfData;
begin
  if (vtNodes = nil) or (ActiveEdit = nil) then Exit;
  
  RootNode := vtNodes.GetFirst;
  while RootNode <> nil do
  begin
    Data := vtNodes.GetNodeData(RootNode);
    if (Data <> nil) and (Data.Edit = ActiveEdit) then
    begin
      vtNodes.Expanded[RootNode] := True;
      ChildNode := vtNodes.GetFirstChild(RootNode);
      if ChildNode <> nil then
      begin
        vtNodes.FocusedNode := ChildNode;
        vtNodes.Selected[ChildNode] := True;
        vtNodes.ScrollIntoView(ChildNode, True);
      end
      else
      begin
        vtNodes.FocusedNode := RootNode;
        vtNodes.Selected[RootNode] := True;
        vtNodes.ScrollIntoView(RootNode, True);
      end;
      Break;
    end;
    RootNode := vtNodes.GetNextSibling(RootNode);
  end;
end;

function TfIDE.LogFile: string;
begin
  result := ParamStr(0) + '.log';
end;

procedure TfIDE.mmoFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  s: string;
  Y: Integer;
begin
  with mmoFind do
  begin
    if Key in [13, 26] then
    begin
      Y := CaretPos.Y;
      s := Lines[Y];
      if (Length(s) > 1) and (s[1] = '>') then // Command
      begin
        if Key = 26 then
          Lines[Y] := '>'
        else
        begin
          Delete(s, 1, 1);
          if s[1] = '?' then
          begin
            if s = '?' then
              s := 'Command: ? cls stack'
            else
              s := DoDebugCmd(s)
            ;
          end
          else if s = 'cls' then
            s := ''
          else if s = 'stack' then
            s := StackText
          else
            exit
          ;
  
          Output(s);
        end; // End of Command
  
        if CaretPos.X > 0 then Key := 0;
      end;
    end;
  end;
end;

// T3: show a transient message in the spare status panel (not overwritten by
// UpdateStatus, which only refreshes panels 0..3).
procedure TfIDE.ShowStatus(const s: string);
begin
  if stats.Panels.Count > 4 then stats.Panels[4].Text := ' ' + s;
end;

// T5: is the caret inside a string literal that directly follows `use`?
// (WordAtCursor/GetWordAtCursor exclude quotes, so scan the line instead.)
function TfIDE.UseStringAtCaret(out s: string): Boolean;
var
  line, prefix: string;
  i, n, p, b, k: Integer;
  q: Char;
begin
  result := false;
  s := '';
  if ActiveEdit = nil then exit;
  if (ActiveEdit.CaretY < 1) or (ActiveEdit.CaretY > ActiveEdit.Lines.Count) then exit;
  line := ActiveEdit.Lines[ActiveEdit.CaretY - 1];
  n := Length(line);
  p := ActiveEdit.CaretX;
  i := 1;
  while i <= n do
  begin
    if (line[i] = '''') or (line[i] = '"') then
    begin
      q := line[i];
      b := i + 1;
      while (b <= n) and (line[b] <> q) do Inc(b);
      if (p >= i) and (p <= b) then // caret inside (or on) the quotes
      begin
        prefix := Trim(Copy(line, 1, i - 1));
        k := Length(prefix);
        while (k > 0) and (prefix[k] <> ' ') and (prefix[k] <> #9) do Dec(k);
        if SameText(Copy(prefix, k + 1, MaxInt), 'use') then
        begin
          s := Copy(line, i + 1, b - i - 1);
          result := true;
        end;
        exit;
      end;
      i := b + 1;
    end
    else
      Inc(i);
  end;
end;

function TfIDE.ResolveUseFile(const f: string): string;
var
  i: Integer;
  cand: array[0..4] of string;
begin
  result := '';
  if f = '' then exit;
  cand[0] := ExtractFilePath(ActiveEdit.FileName) + f; // next to the current file
  cand[1] := ExtractFilePath(ParamStr(0)) + f;         // exe directory
  cand[2] := ExtractFilePath(ParamStr(0)) + 'lib\' + f;// exe\lib
  cand[3] := ExtractFilePath(ParamStr(0)) + 'app\' + f;// exe\app (core parity)
  cand[4] := f;                                        // as given / cwd
  for i := 0 to High(cand) do
    if (cand[i] <> '') and FileExists(cand[i]) then
    begin
      result := cand[i];
      exit;
    end;
end;

function TfIDE.GotoUseAtCaret: Boolean;
var
  s, fn: string;
begin
  result := false;
  if (ActiveEdit = nil) or IsRunning then exit;
  if not UseStringAtCaret(s) then exit;
  fn := ResolveUseFile(s);
  if fn = '' then
  begin
    ShowStatus('File not found: ' + s);
    exit;
  end;
  OpenTab(fn);
  result := true;
end;

procedure TfIDE.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) and GotoUseAtCaret then
    Key := 0;
end;

procedure TfIDE.EditMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // OpenTab/SetFocus cannot run while the editor is handling a mouse-down on a
  // control whose tab is about to change ("Cannot focus a disabled or
  // invisible window"), so defer the jump to the next message-loop pass.
  if (Button = mbLeft) and (ssCtrl in Shift) then
    PostMessage(Handle, WM_USER + 200, 0, 0);
end;

procedure TfIDE.WMGotoUse(var msg: TMessage);
begin
  GotoUseAtCaret;
end;

// T6: `>stack`. With -dFunTraceback the runtime already keeps a real dynamic
// call chain, and traceBack returns it as clickable `  in name() (file:line)`
// lines. Without the define, fall back to lastErrorFun plus the last traced
// node, and say so.
function TfIDE.StackText: string;
var
  t: string;
  n: CNode;
  m: CModu;
begin
  if _ENV = nil then
  begin
    result := '(stack: no environment; not running)';
    exit;
  end;
  t := _ENV.traceBack;
  if t <> '' then
  begin
    result := t;
    exit;
  end;
  result := '(stack: call chain unavailable; best-effort)' + sLineBreak;
  t := _ENV.lastErrorFun;
  if t <> '' then result := result + ' in ' + t + sLineBreak;
  n := _ENV.lastNode;
  if n is CRune then
  begin
    if n.root is CModu then m := CModu(n.root) else m := nil;
    if (m <> nil) and (m.fileName <> '') then
      result := result + ' at ' + m.fileName + ':' + IntToStr(CRune(n).row) + sLineBreak
    else
      result := result + ' at line ' + IntToStr(CRune(n).row) + sLineBreak;
  end;
end;

// T3: `file:line: ` prefix for a runtime error, from the failed node. Mirrors
// the command-line driver's ErrPos (fun/src/prj/fun/funcmd.dpr).
function TfIDE.LastErrorPos: string;
var
  n: CNode;
  m: CModu;
begin
  result := '';
  if _ENV = nil then exit;
  n := _ENV.lastNode;
  if not (n is CRune) then exit;
  if n.root is CModu then m := CModu(n.root) else m := nil;
  if (m <> nil) and (m.fileName <> '') then
    result := m.fileName + ':' + IntToStr(CRune(n).row) + ': ';
end;

// T3: match a jump target on an output line. Three forms are recognised:
//   "<msg> @ <row>,<col>"   (parse error; no file -> caller uses active file)
//   "<file>(<line>)"        (fun-style location)
//   "<file>:<line>" / "(<file>:<line>)" (runtime prefix and traceBack frames)
function TfIDE.LocFromOutputLine(const line: string; out fn: string; out row: Integer): Boolean;
var
  i, j, k, n: Integer;

  function Clean(const v: string): string;
  var
    p, q: Integer;
    t: string;
  begin
    t := Trim(v);
    // cut to a Windows drive root (<letter>:\ or <letter>:/) if present, so a
    // leading word such as "at"/"in" in the message text is dropped
    for p := Length(t) downto 3 do
      if (t[p] in ['\', '/']) and (t[p-1] = ':') and (t[p-2] in ['A'..'Z', 'a'..'z']) then
      begin
        result := Trim(Copy(t, p - 2, MaxInt));
        exit;
      end;
    // otherwise drop any leading "where:" text up to the last '(' or ')'
    q := LastDelimiter('()', t);
    if q > 0 then t := Trim(Copy(t, q + 1, MaxInt));
    // and if a leading word remains (e.g. "at"), keep the last whitespace token
    if Pos(' ', t) > 0 then
    begin
      q := Length(t);
      while (q > 0) and (t[q] <> ' ') and (t[q] <> #9) do Dec(q);
      t := Trim(Copy(t, q + 1, MaxInt));
    end;
    result := t;
  end;

  function Accept(const v: string; arow: Integer): Boolean;
  begin
    result := (v <> '') and (Pos('.', v) > 0);
    if result then
    begin
      fn  := v;
      row := arow;
    end;
  end;

begin
  result := false;
  fn := '';
  row := 0;
  n := Length(line);
  // parse-error form "<msg> @ <row>,<col>" (no file name)
  i := Pos(' @ ', line);
  if i > 0 then
  begin
    j := i + 3;
    k := j;
    while (k <= n) and (line[k] in ['0'..'9']) do Inc(k);
    if k > j then
    begin
      row := StrToInt(Copy(line, j, k - j));
      result := true;
      exit;
    end;
  end;
  // "file(line)"
  for i := 1 to n do
    if line[i] = '(' then
    begin
      j := i + 1;
      k := j;
      while (k <= n) and (line[k] in ['0'..'9']) do Inc(k);
      if (k > j) and (k <= n) and (line[k] = ')') then
        if Accept(Clean(Copy(line, 1, i - 1)), StrToInt(Copy(line, i + 1, k - i - 1))) then
        begin
          result := true;
          exit;
        end;
    end;
  // "file:line"
  for i := n downto 1 do
    if line[i] = ':' then
    begin
      j := i + 1;
      k := j;
      while (k <= n) and (line[k] in ['0'..'9']) do Inc(k);
      if k > j then
        if Accept(Clean(Copy(line, 1, i - 1)), StrToInt(Copy(line, i + 1, k - i - 1))) then
        begin
          result := true;
          exit;
        end;
    end;
end;

procedure TfIDE.mmoReplaceDblClick(Sender: TObject);
var
  fn: string;
  row: Integer;
begin
  if (mmoReplace.CaretPos.Y < 0) or (mmoReplace.CaretPos.Y >= mmoReplace.Lines.Count) then exit;
  if not LocFromOutputLine(mmoReplace.Lines[mmoReplace.CaretPos.Y], fn, row) then exit;
  if fn = '' then
  begin
    if ActiveEdit = nil then exit;
    fn := ActiveEdit.FileName; // parse errors carry no file name
  end;
  if (fn <> '') and FileExists(fn) then
  begin
    OpenTab(fn);
    ActiveEdit.GotoLineAndCenter(row);
    ActiveEdit.EnsureCursorPosVisible;
  end
  else
    ShowStatus('File not found: ' + fn);
end;

procedure TfIDE.NewTab;
var
  t: TfTab;
begin
  t := TfTab.Create(tabs);
  t.Title         := 'none ' + IntToStr(tabs.PageCount);
  t.BorderWidth   := 0;
  t.PageControl   := tabs;
  tabs.ActivePage := t;
  
  t.fEdit.OnDropFiles := DropFiles;
  t.fEdit.PopupMenu   := pmEdit;
  t.fEdit.OnKeyDown   := EditKeyDown;   // T5: Ctrl+Enter on use '...'
  t.fEdit.OnMouseDown := EditMouseDown; // T5: Ctrl+Click on use '...'
  t.fEdit.WordWrap    := aWordWrap.Checked;
  t.fEdit.ImageList   := il1;
  if t.fEdit.CanFocus then t.fEdit.SetFocus;
  if fInis.Values['Font-Name'] <> '' then t.fEdit.Font.Name := fInis.Values['Font-Name'];
  if fInis.Values['Font-Size'] <> '' then t.fEdit.Font.Size := StrToInt(fInis.Values['Font-Size']);
  if fInis.Values['RightEdge'] <> '' then t.fEdit.RightEdge := StrToInt(fInis.Values['RightEdge']);
  if fInis.Values['ExtraLineSpacing'] <> '' then t.fEdit.ExtraLineSpacing := StrToInt(fInis.Values['ExtraLineSpacing']);
end;

procedure TfIDE.OpenTab(const f: string);
begin
  if CheckExists(f) then exit;
  
  if (tabs.ActivePage <> nil)
    and (ActiveEdit.FileName = '')
    and (ActiveEdit.Text = '')
    then
    //
  else
    NewTab
  ;
  
  TfTab(tabs.ActivePage).FileName := f;
  TfTab(tabs.ActivePage).Load();
  AddLog(f);
end;

procedure TfIDE.Output(const s: string; len: Integer = 4*1024*1024);
begin
  with mmoReplace do
  begin
    Lines.BeginUpdate;
    WordWrap := False; // So fast !
    try
      if Length(s) > len then
        Text := Copy(s, 1, len) + '......' + Copy(s, Length(s)-255, 256)
      else
        Text := s
      ;
      if Lines.Count < 1000 then WordWrap := True;
    finally
      Lines.EndUpdate;
    end;
  end;
end;

procedure TfIDE.PresetItemClick(Sender: TObject);
var
  mi: TMenuItem;
begin
  mi := Sender as TMenuItem;
  mmoFind.Text := mi.Hint;
  aFindRegex.Checked := True;
  aFindAllExecute(Sender);
end;

procedure TfIDE.RefreshTree;
begin
  if vtNodes = nil then exit;
  if vtNodes.UpdateCount > 0 then exit;
  vtNodes.RootNodeCount := 0;
  vtNodes.RootNodeCount := Files.CountVisible();
end;

procedure TfIDE.RemFile(const fn: string);
begin
  Files.add(fn, nil, true);
  RefreshTree;
end;

procedure TfIDE.Search(so: TSynSearchOptions = []);
var
  Options: TSynSearchOptions;
  s: string;
begin
  if ActiveEdit = nil then exit;
  Options := GetSearchOptions(so);
  s := mmoFind.Text;
  if not aFindRegex.checked then s := '\Q' + s + '\E';
  if aFindWholeWord.checked then s := '\b' + s + '\b';
  ActiveEdit.SearchReplace(s, mmoReplace.Text, Options);
end;

// Status bar clicks:
//   Panels[2] (file format) switches CRLF (DOS) <-> LF (UNIX);
//   Panels[3] (encoding) re-reads the file as ANSI <-> UTF-8.
// TStatusBar here has no OnPanelClick, so the clicked panel is located from
// the click position via the SB_GETRECT status bar message.
procedure TfIDE.statsClick(Sender: TObject);
const
  es: array[TSynEncoding] of string = ('UTF-8', 'UCS-2 LE', 'UCS-2 BE', 'ANSI');
  SB_GETRECT = $040A; // WM_USER + 10: bounding rect of a status panel
var
  pt: TPoint;
  r: TRect;
  i: Integer;
  enc: TSynEncoding;
begin
  if (ActiveEdit = nil) or IsRunning then exit;
  GetCursorPos(pt);
  pt := stats.ScreenToClient(pt);
  for i := stats.Panels.Count - 1 downto 0 do
    if stats.Panels[i].Text <> '' then
    begin
      SendMessage(stats.Handle, SB_GETRECT, WPARAM(i), LPARAM(@r));
      if (pt.X >= r.Left) and (pt.X < r.Right) and
         (pt.Y >= r.Top)  and (pt.Y < r.Bottom) then
      begin
        with ActiveEdit do
        begin
          if i = 3 then
          begin
            if Encoding = seAnsi then enc := seUTF8 else enc := seAnsi;
            if (FileName <> '') and Modified then
              if MessageBox(0, PChar('Reload [' + DisplayName + '] as ' + es[enc] +
                   '?'#13#10'Unsaved changes will be lost.'), 'Confirmation',
                   MB_OKCANCEL or MB_ICONQUESTION) <> IDOK then
                exit;
            ReLoad(enc);
          end
          else if i = 2 then
          begin
            if TSynEditStringList(Lines).FileFormat = sffDos then
              TSynEditStringList(Lines).FileFormat := sffUnix
            else
              TSynEditStringList(Lines).FileFormat := sffDos;
            Modified := True;
          end
          else
            exit;
        end;
        UpdateStatus;
        exit;
      end;
    end;
end;

procedure TfIDE.TreeFocusChange(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
var
  data: PfData;
begin
  data := Sender.GetNodeData(Node);
  if data = nil then exit;
  if data.Level = 0 then
    CheckExists(data.Edit.FileName)
  else
  begin
    CheckExists(data.Edit.FileName);
    data.Edit.GotoLineAndCenter(data.Index);
  end;
end;

procedure TfIDE.TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex:
        Integer);
var
  data: PfData;
begin
  data := Sender.GetNodeData(Node);
  if data = nil then exit;
  ImageIndex := data.Image;
  if ImageIndex = 0 then ImageIndex := -1;
  if data.Level = 1 then
  begin
    if {not IsRunning and} (data.Image in [ImgBreakPoint]) then
      ImageIndex := imgBreakFake;
  end;
end;

procedure TfIDE.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: UnicodeString);
var
  data: PfData;
  sLine: string;
begin
  data := Sender.GetNodeData(Node);
  if data = nil then exit;
  if data.Level = 0 then
    CellText := data.Edit.DisplayName + ' (' + IntToStr(Node.ChildCount) + ')'
  else
  begin
    if (data.Image = ImgBookmark) and (data.Edit <> nil) and
       (data.Index > 0) and (data.Index <= data.Edit.Lines.Count) then
    begin
      sLine := TrimRight(data.Edit.Lines[data.Index - 1]);
      if Length(sLine) > 80 then
        sLine := Copy(sLine, 1, 80) + WideChar($2026);
      CellText := Format('%s - %d', [sLine, data.Index]);
    end
    else
      CellText := IntToStr(data.Index);
  end;
end;

procedure TfIDE.TreeInitChildren(Sender: TBaseVirtualTree; Node: PVirtualNode; var ChildCount: Cardinal);
var
  data: PfData;
begin
  data := Sender.GetNodeData(Node);
  if data = nil then exit;
  ChildCount := data.Edit.CountMark;
end;

procedure TfIDE.TreeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var
  i, ii: Integer;
  fStates: ArrayOfByte;
  data: PfData;
begin
  Data := Sender.GetNodeData(Node);
  if data = nil then exit;
  Data.Level := Sender.GetNodeLevel(Node);
  
  if Data.Level = 0 then
  begin
    Node.States := Node.States + [vsHasChildren, vsExpanded];
  
    ii := Files.count;
    i  := 0;
    if Node.PrevSibling <> nil then
      i := PfData(Sender.GetNodeData(Node.PrevSibling)).Index + 1;
    while i < ii do
    begin
      if Files[i].Edit = nil then
        inc(i)
      else
        break
      ;
    end;
    Data.Index := i;
    Data.Image := imgClass;
    Data.Edit  := Files[i].Edit;
  end
  else
  begin
    Data.Edit := PfData(Sender.GetNodeData(ParentNode)).Edit;
    fStates   := data.Edit.fStates;
    ii := Length(fStates);
    i  := 0;
    if Node.PrevSibling <> nil then
      i := PfData(Sender.GetNodeData(Node.PrevSibling)).Index + 1;
    while i < ii do
    begin
      if fStates[i] = 0 then
        inc(i)
      else
        break
      ;
    end;
    Data.Index := i;
    Data.Image := fStates[i];
  end;
end;

procedure TfIDE.UpdateStatus(Sender: TObject = nil);
  
  const
    ff: array [TSynEditFileFormat] of string = ('DOS', 'UNIX', 'Mac', 'Unicode');
    es: array[TSynEncoding] of string = ('UTF-8', 'UCS-2 LE', 'UCS-2 BE', 'ANSI');
  var
    b: Boolean;
    OldXY: TBufferCoord;
    OldY: Integer;
  
begin
  if DontUpdate then exit;
  
  b := tabs.ActivePage <> nil;
  if Integer(b) <> Old then
  begin
    aSave.Enabled     := b;
    aFind.Enabled     := b;
    aWordWrap.Enabled := b;
    aSpecChar.Enabled := b;
    aOptions.Enabled  := b;
    pr.Enabled        := b;
    tlb1.Enabled      := b;
    tlb2.Enabled      := b;
    aBreakPoint.Enabled := b;
    if not b then
    begin
      aCopy.Enabled     := b;
      aCut.Enabled      := b;
      aPaste.Enabled    := b;
      aUndo.Enabled     := b;
      aRedo.Enabled     := b;
      aRun.Enabled        := b;
      aPause.Enabled      := b;
      aStop.Enabled       := b;
      aStepOver.Enabled   := b;
      aStepInto.Enabled   := b;
      aStepOut.Enabled    := b;
      aStepMore.Enabled   := b;
    end;
  
    Old := Integer(b);
  end;
  
  if not b then exit;
  
  with ActiveEdit do
  begin
    with TfTab(Parent) do if Modified then
      ImageIndex := ImageModified
    else
      ImageIndex := ImageSaved
    ;
    with stats do
    begin
      Panels[0].Text := Format(' %d Lines - @%d,%d - (%d,%d)',
                          [Lines.Count, CaretY, CaretX, SelStart, SelLength]);
      if InsertMode then
        Panels[1].Text := 'INS'
      else
        Panels[1].Text := 'OVR'
      ;
      // File Format
      Panels[2].Text   := ff[TSynEditStringList(Lines).FileFormat];
      // File Encoding
      if BOM then Panels[3].Text := es[Encoding] + ' BOM'
             else Panels[3].Text := es[Encoding];
    end;
  
    ReadOnly          := IsRunning;
    b := not ReadOnly and aFindRegex.Checked;
    mmoFind.Highlighter.Enabled := b;
    if b then
      mmoFind.ActiveLineColor := clNone
    else
      mmoFind.ActiveLineColor := $f4f8f8
    ;
    aReplace.Enabled  := not ReadOnly;
    aReplaceAll.Enabled := aReplace.Enabled;
    aWordWrap.Checked := WordWrap;
    aSpecChar.Checked := eoShowSpecialChars in Options;
    aCopy.Enabled     := SelLength > 0;
    aCut.Enabled      := SelLength > 0;
    aPaste.Enabled    := CanPaste;
    aUndo.Enabled     := CanUndo;
    aRedo.Enabled     := CanRedo;
  
    aRun.Enabled      := not IsRunning or IsRunning and IsBreaked;
    aPause.Enabled    := IsRunning and not IsBreaked;
    aStop.Enabled     := IsRunning;
    aStepOver.Enabled := aRun.Enabled;
    aStepInto.Enabled := aRun.Enabled;
    aStepOut.Enabled  := aRun.Enabled;
    aStepMore.Enabled := aRun.Enabled;
  
    if not isRunning then Hint := '';
  
    if FileName <> '' then
    begin
      if GetTime(FileName) <> LastTime then
      begin
        if Modified then
        begin
          DontUpdate := True;
          case MessageBox(0, PChar('['+DisplayName+'] has been changed, reload?'), 'Confirmation', MB_YESNO	or MB_ICONQUESTION) of
            IDYES: Load();
            else   LastTime := GetTime(FileName);
          end;
          DontUpdate := False;
        end else
        begin
          OldXY := CaretXY;
          OldY  := TopLine;
          Lines.BeginUpdate;
          try
            Load();
            CaretXY := OldXY;
            TopLine := OldY;
          finally
            Lines.EndUpdate;
          end;
        end;
      end;
    end;
  end;
  
  Evaluate;
end;

procedure TfIDE.WMDropFiles(var msg: TMessage);
  
  const
    PathLength = 1024;
  var
    name: array[0..PathLength-1] of Char;
    I, II: integer;
    S: string;
    SS: TUnicodeStringList;
  
begin
  SS := TUnicodeStringList.Create;
  II := DragQueryFile(msg.wParam, $FFFFFFFF, name, PathLength);
  for I := 0 to II - 1 do
  begin
    DragQueryFile(msg.wParam, I, name, PathLength);
    S := StrPas(name);
    SS.Add(S);
  end;
  DragFinish(msg.wParam);
  
  try
    DropFiles(Self, 0, 0, SS);
  finally
    SS.Free;
  end;
end;

//==============================================================
procedure TPageControl.TCMAdjustRect(var Msg: TMessage);
begin
  inherited;
  if Msg.WParam = 0 then
    InflateRect(PRect(Msg.LParam)^, 4, 4)
  else
    InflateRect(PRect(Msg.LParam)^, -4, -4);
end;

procedure TPageControl.WMLButtonUp(var Message: TWMLButtonUp);
begin
  inherited;
  if ActivePage = nil then exit;
  with Message.Pos, TabRect(ActivePageIndex) do
  begin
    if (X < Right) and (X > Right - 16) then fIDE.aCloseExecute(Self);
  end;
end;

//==============================================================
destructor TSplitter.Destroy;
begin
  FreeAndNil(TempBrush);
  inherited Destroy;
end;

procedure TSplitter.CMMouseEnter(var AMsg: TMessage);
var
  pt: TPoint;
begin
  fMouseIn := true;
  Color    := clWhite;
  Refresh;
  
  GetCursorPos(pt);
  pt := ScreenToClient(pt);
  MouseMove([], pt.X, pt.Y);
end;

procedure TSplitter.CMMouseLeave(var AMsg: TMessage);
begin
  fMouseIn := false;
  Color    := clBtnFace;
  Refresh;
end;

function TSplitter.DoCanResize(var NewSize: Integer): Boolean;
begin
  if fInGrab then
  begin
    if OldSize = 0 then
    begin
      OldSize := NewSize;
      NewSize := 0;
    end
    else
    begin
      NewSize := OldSize;
      if NewSize = 0 then NewSize := 30;
      OldSize := 0;
    end;
    Result  := True;
  end
  else Result := inherited DoCanResize(NewSize);
end;

function TSplitter.GetGrabRect: TRect;
var
  I: Integer;
begin
  Result := ClientRect;
  I := (GrabLength + 1) * 3;
  if (Align in [alLeft, alRight]) then
  begin
    I := (Result.Bottom - Result.Top - I) div 2 - 1;
    Inc(Result.Top,    I);
    Dec(Result.Bottom, I);
  end
  else
  begin
    I := (Result.Right - Result.Left - I) div 2 - 1;
    Inc(Result.Left,  I);
    Dec(Result.Right, I);
  end;
end;

function TSplitter.GrabLength: Integer;
begin
  Result := 25;
end;

function TSplitter.InGrabRect(X, Y: Integer): Boolean;
begin
  Result := PtInRect(GrabRect, Point(X, Y));
end;

procedure TSplitter.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if fInGrab then
  begin
    MouseMove(Shift, X, Y);
    MouseUp(Button, Shift, X, Y);
  end;
end;

procedure TSplitter.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Shift = [] then
  begin
    fInGrab  := InGrabRect(X, Y);
    if fInGrab then
      Cursor := crHandPoint
    else if Align in [alLeft, alRight] then
      Cursor := crHSplit
    else
      Cursor := crVSplit
    ;
    Windows.SetCursor(Screen.Cursors[Cursor]); // show immediatelly
  end;
end;

procedure TSplitter.Paint;
var
  i, X, Y, CX, CY, DX, DY: Integer;
  
  procedure DrawLine(Offset: Integer = 0);
  begin
    if MouseIn then
      Canvas.Pen.Color := clBlack
    else
      Canvas.Pen.Color := $808080
    ;
    if CX = 0 then
    begin
      Canvas.MoveTo(X+Offset, 0);
      Canvas.LineTo(X+Offset, CY);
    end
    else
    begin
      Canvas.MoveTo(0,  Y+Offset);
      Canvas.LineTo(CX, Y+Offset);
    end;
  
    inc(X, DX);
    inc(Y, DY);
  end;
  
begin
  inherited;
  try
    Canvas.Pen.Color   := clActiveBorder;
    Canvas.Brush.Color := Color;
    Canvas.Rectangle(0, 0, Width, Height);
  
    GrabRect := GetGrabRect;
    with GrabRect do if Align in [alLeft, alRight] then
    begin
      X  := (Left + Right) div 2;
      Y  := Top;
      DX := 0;
      DY := 3;
      CX := Right - Left;
      CY := 0;
    end
    else
    begin
      X  := Left;
      Y  := (Top + Bottom) div 2;
      DX := 3;
      DY := 0;
      CX := 0;
      CY := Bottom - Top;
    end;
  
    if TempBrush = nil then
    begin
      TempBrush := TBitmap.Create;
      TempBrush.SetSize(2, 2);
      TempBrush.Canvas.Brush.Color := clBtnHighlight;
      TempBrush.Canvas.FillRect(Rect(0,0,1,1));
    end;
  
    if MouseIn then
      TempBrush.Canvas.Pixels[0, 0] := clBtnText
    else
      TempBrush.Canvas.Pixels[0, 0] := clBtnShadow;
    ;
  
    DrawLine(-1);
    for i := 0 to GrabLength do
    begin
      Canvas.Draw(X, Y, TempBrush);
      inc(X, DX);
      inc(Y, DY);
    end;
    DrawLine;
  except
  end;
end;

procedure TSplitter.Resize;
begin
  inherited;
  GrabRect := GetGrabRect;
end;

//==============================================================
constructor TMemo.Create(AOwner: TComponent);
begin
  inherited;
  Highlighter := TRegexSyntax.Create(Self);
  Highlighter.Enabled := False;
  
  Parent      := TWinControl(AOwner);
  Options     := Options + [
                            eoAltSetsColumnMode,
                          //eoDropFiles,
                            eoHideShowScrollBars
                           ]
                         - [
                           ];
  BorderStyle := bsNone;
  WordWrap    := True;
  Font.Size   := 8;
  ActiveLineColor       := $f4f8f8;
  Gutter.Visible        := False;
  //WordWrapGlyph.Visible := False;
  with BookMarkOptions do
  begin
  //  EnableKeys          := False;
  //  GlyphsVisible       := False;
  end;
end;

function TMemo.CaretPos: TPoint;
begin
  Result.Y := CaretY - 1;
  Result.X := CaretX - 1;
end;


//////////////////////////////////////////////////
function MakeDrop(const FileName: AnsiString): THandle;
var
  Size: Integer;
  Data: PDragInfoA;
  P: PAnsiChar;
begin
  Size := SizeOf(TDragInfoA) + 1;
  Inc(Size, Length(FileName) + 1);

  Result := GlobalAlloc(GHND or GMEM_SHARE, Size);
  if Result <> 0 then
  begin
    Data := GlobalLock(Result);
    if Data <> nil then
    try
      Data.uSize := SizeOf(TDragInfoA);
      P  := PAnsiChar(@Data.grfKeyState) + 4;
      Data.lpFileList := P;

      Size := Length(FileName);
      Move(Pointer(FileName)^, P^, Size);
    finally
      GlobalUnlock(Result);
    end
    else
    begin
      GlobalFree(Result);
      Result := 0;
    end;
  end;
end;

function FindIDE: Boolean;
var
  s: string;
  Wnd: HWnd;
  Drop: hDrop;
begin
  Result := False;

  s := ParamStr(1);
  if (s <> '') and FileExists(s) then
  begin
    Wnd := FindWindow('TfIDE', nil);
    if Wnd <> 0 then
    begin
      Drop := MakeDrop(s);
      if Drop <> 0 then
      begin
        PostMessage(Wnd, WM_DropFiles, Drop, 0);
        //GlobalFree(Drop);
        SetForegroundWindow(Wnd);

        Result := True;
      end;
    end;
  end;
end;

end.
