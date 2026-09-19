// $Id: debug.pas v1.00 2012/08/23 11:30:00 (c) www.funlang.org $
//
//  Revision History
//  ----------------
//
//  2012/08/23
//      Created
//
//**************************************************************

unit debug;

interface

uses fun, base, core, host, parse;

type
  CdRunner = class(CEnv2)
  public
    function clone: CEnv; override;
    procedure echo(const s: fun.str); override;
    procedure trace(n: CNode); override;
    procedure traced(n: CNode; tracing: fun.bool = false); override;
  end;
  
  CdParser = class(CParser)
  protected
    procedure OnParse(p: CParser); overload; override;
    procedure OnParse(n: CRune); overload; override;
    procedure OnParse(const fn: fun.str; var s: fun.str; m: core.CModu = nil); overload; override;
  public
    procedure DoError(const s: fun.str); overload; override;
  end;
  

implementation

//==============================================================
function CdRunner.clone: CEnv;
begin
  result := CdRunner.create;
end;

procedure CdRunner.echo(const s: fun.str);
begin
  // todo
end;

procedure CdRunner.trace(n: CNode);
begin
  inherited trace(n);
  // todo
end;

procedure CdRunner.traced(n: CNode; tracing: fun.bool = false);
begin
  // todo
end;

//==============================================================
procedure CdParser.DoError(const s: fun.str);
begin
  // todo
end;

procedure CdParser.OnParse(p: CParser);
begin
  //todo
end;

procedure CdParser.OnParse(n: CRune);
begin
  //todo
end;

procedure CdParser.OnParse(const fn: fun.str; var s: fun.str; m: core.CModu = nil);
begin
  // todo
end;


end.
