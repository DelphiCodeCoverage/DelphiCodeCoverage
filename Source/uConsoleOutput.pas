unit UConsoleOutput;

interface

uses
  I_LogManager;

procedure ConsoleOutput(const AMessage: string);
procedure VerboseOutput(const AMessage: string);

var
  G_Verbose_Output: Boolean;
  G_LogManager: ILogManager;

implementation

procedure Log(const AMessage: string);
begin
  if Assigned(G_LogManager) then
  begin
    G_LogManager.Log(AMessage);
  end;
end;

procedure ConsoleOutput(const AMessage: string);
begin
  {$IFNDEF CONSOLE_TESTRUNNER}
  if IsConsole then
  begin
    Writeln(AMessage);
  end;
  {$ENDIF}
  Log(AMessage);
end;

procedure VerboseOutput(const AMessage: string);
begin
  if G_Verbose_Output then
  begin
    ConsoleOutput(AMessage);
  end
  else
  begin
    Log(AMessage);
  end;
end;

initialization
  G_Verbose_Output := False;
  G_LogManager := nil;
end.
