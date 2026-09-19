program funide;

uses
  Forms, SysUtils,
  io,
  ide in '..\..\ide\ide.pas' {fIDE},
  funsyntax in '..\..\ide\funsyntax.pas',
  regexsyntax in '..\..\ide\regexsyntax.pas',
  fdsyntax in '..\..\ide\fdsyntax.pas',
  pcrd in '..\..\regex\pcre\pcrd.pas',
  pcre in '..\..\regex\pcre\pcre.pas';

{$R *.res}

begin
  if not FindIDE then
  begin
    try
      Application.Initialize;
      {$IfDef Unicode}
      Application.MainFormOnTaskbar := True;
      {$EndIf}
      Application.CreateForm(TfIDE, fIDE);
      Application.Run;
    except
      on e: Exception do
        CIO.save(ParamStr(0) + '.error.log', e.Message);
    end;
  end;
end.
