(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)
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
  CoverageConfiguration in '..\Source\CoverageConfiguration.pas',
  CoverageConfigurationTest in 'CoverageConfigurationTest.pas',
  MockCommandLineProvider in 'MockCommandLineProvider.pas',
  ClassInfoUnitTest in 'ClassInfoUnitTest.pas',
  ClassInfoUnit in '..\Source\ClassInfoUnit.pas',
  uConsoleOutput in '..\Source\uConsoleOutput.pas',
  EmmaFileHelper in '..\Source\EmmaFileHelper.pas',
  EmmaDataInputTests in 'EmmaDataInputTests.pas',
  EmmaDataOutputTests in 'EmmaDataOutputTests.pas',
  ModuleNameSpaceUnit in '..\Source\ModuleNameSpaceUnit.pas',
  I_CoverageConfiguration in '..\Source\I_CoverageConfiguration.pas',
  I_LogManager in '..\Source\I_LogManager.pas',
  I_Logger in '..\Source\I_Logger.pas',
  I_ParameterProvider in '..\Source\I_ParameterProvider.pas',
  LoggerTextFile in '..\Source\LoggerTextFile.pas',
  LoggerAPI in '..\Source\LoggerAPI.pas',
  I_BreakPoint in '..\Source\I_BreakPoint.pas',
  I_Debugger in '..\Source\I_Debugger.pas',
  I_DebugModule in '..\Source\I_DebugModule.pas',
  I_DebugProcess in '..\Source\I_DebugProcess.pas',
  I_DebugThread in '..\Source\I_DebugThread.pas',
  CoverageStatsMergeTests in 'CoverageStatsMergeTests.pas',
  CoverageStats in '..\Source\CoverageStats.pas',
  I_CoverageStats in '..\Source\I_CoverageStats.pas',
  XMLCoverageReport in '..\Source\XMLCoverageReport.pas',
  I_Report in '..\Source\I_Report.pas';

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
