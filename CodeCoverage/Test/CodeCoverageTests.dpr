program CodeCoverageTests;
{

 Delphi DUnit Test Project
 -------------------------
 This project contains the DUnit test framework and the GUI/Console test runners.
 Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
 to use the console test runner.  Otherwise the GUI test runner will be used by
 default.

}
{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Classes,
  SysUtils,
  Windows,
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  CoverageConfiguration in '..\CoverageConfiguration.pas',
  CoverageConfigurationTest in 'CoverageConfigurationTest.pas',
  I_CoverageConfiguration in '..\I_CoverageConfiguration.pas',
  I_ParameterProvider in '..\I_ParameterProvider.pas',
  MockCommandLineProvider in 'MockCommandLineProvider.pas',
  ClassInfoUnitTest in 'ClassInfoUnitTest.pas',
  ClassInfoUnit in '..\ClassInfoUnit.pas',
  I_BreakPoint in '..\I_BreakPoint.pas',
  I_BreakpointList in '..\I_BreakpointList.pas',
  I_CoverageStats in '..\I_CoverageStats.pas',
  I_Debugger in '..\I_Debugger.pas',
  I_DebugProcess in '..\I_DebugProcess.pas',
  I_DebugThread in '..\I_DebugThread.pas';

{$R *.RES}

begin
  try
    Application.Initialize;
    if IsConsole then
      with TextTestRunner.RunRegisteredTests do
        Free
      else
        GUITestRunner.RunRegisteredTests;
  except
    on E: Exception do
    begin
      if IsConsole then
      begin
        writeln('Exception caught:');
        writeln(#9 + E.ClassName);
        writeln(#9 + E.Message);
      end
      else
      begin
        Application.MessageBox(PChar(E.ClassName +
                                     System.sLineBreak +
                                     E.Message),
                               'Exception Caught',
                               MB_ICONERROR or MB_OK);
      end;
    end;
  end;
end.
