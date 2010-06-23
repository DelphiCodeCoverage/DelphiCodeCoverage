program CodeCoverage;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Debugger in 'Debugger.pas',
  DebugProcess in 'DebugProcess.pas',
  DebugThread in 'DebugThread.pas',
  BreakPoint in 'BreakPoint.pas',
  CoverageResult in 'CoverageResult.pas',
  logger in 'logger.pas',
  CoverageReport in 'CoverageReport.pas';

var
  Debugger: TDebugger;

begin
  try
    Debugger := TDebugger.Create;
    Debugger.start();
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.message);
  end;

end.
