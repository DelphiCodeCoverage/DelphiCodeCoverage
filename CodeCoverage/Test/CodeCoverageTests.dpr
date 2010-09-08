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
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  TestConfiguration in 'TestConfiguration.pas',
  CoverageConfiguration in '..\CoverageConfiguration.pas',
  I_CoverageConfiguration in '..\I_CoverageConfiguration.pas',
  I_ParameterProvider in '..\I_ParameterProvider.pas';
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
      writeln('Exception caught:' + E.ToString);
  end;

end.
