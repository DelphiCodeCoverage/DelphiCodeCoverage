unit uConsoleOutput;

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
    G_LogManager.Log(AMessage);
end;

procedure ConsoleOutput(const AMessage: string);
begin
  {$IFNDEF CONSOLE_TESTRUNNER}
  if IsConsole then
    Writeln(AMessage);
  {$ENDIF}
  Log(AMessage);
end;

procedure VerboseOutput(const AMessage: string);
begin
  if G_Verbose_Output then
    ConsoleOutput(AMessage)
  else
    Log(AMessage);
end;

initialization
  G_Verbose_Output := False;
  G_LogManager := nil;
end.
