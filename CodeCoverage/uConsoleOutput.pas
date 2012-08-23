unit uConsoleOutput;

interface

procedure ConsoleOutput(const AMessage: string);
procedure VerboseOutput(const AMessage: string);

var
  G_Verbose_Output: Boolean;

implementation

procedure ConsoleOutput(const AMessage: string);
begin
  if IsConsole then
    Writeln(AMessage);
end;

procedure VerboseOutput(const AMessage: string);
begin
  if G_Verbose_Output then
    ConsoleOutput(AMessage);
end;

initialization
  G_Verbose_Output := False;
end.
