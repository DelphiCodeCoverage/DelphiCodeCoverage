program CodeCoverageTests;

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
  XmlTestRunner,
  StrUtilsD9Tests in 'StrUtilsD9Tests.pas',
  StrUtilsD9 in '..\..\3rdParty\StrUtilsD9.pas',
  CoverageConfiguration in '..\CoverageConfiguration.pas',
  CoverageConfigurationTest in 'CoverageConfigurationTest.pas',
  MockCommandLineProvider in 'MockCommandLineProvider.pas',
  ClassInfoUnitTest in 'ClassInfoUnitTest.pas',
  ClassInfoUnit in '..\ClassInfoUnit.pas',
  uConsoleOutput in '..\uConsoleOutput.pas',
  FileHelper in '..\FileHelper.pas',
  EmmaDataInputTests in 'EmmaDataInputTests.pas',
  EmmaDataOutputTests in 'EmmaDataOutputTests.pas',
  ModuleNameSpaceUnit in '..\ModuleNameSpaceUnit.pas';

{$R *.RES}

begin
  try
    Application.Initialize;
    if IsConsole then
      XmlTestRunner.RunTestsAndClose
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
