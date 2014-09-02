(*
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * The Original Code is DUnit.
 *
 * The Initial Developers of the Original Code are Kent Beck, Erich Gamma,
 * and Juancarlo Aez.
 * Portions created The Initial Developers are Copyright (C) 1999-2000.
 * Portions created by The DUnit Group are Copyright (C) 2000-2003.
 * All rights reserved.
 *
 * Contributor(s):
 * Kent Beck <kentbeck@csi.com>
 * Erich Gamma <Erich_Gamma@oti.com>
 * Juanco Aez <juanco@users.sourceforge.net>
 * Chris Morris <chrismo@users.sourceforge.net>
 * Jeff Moore <JeffMoore@users.sourceforge.net>
 * Kris Golko <neuromancer@users.sourceforge.net>
 * The DUnit group at SourceForge <http://dunit.sourceforge.net>
 *)

{
 Contributor : Martin Gondermann <magicmonty@pagansoft.de>
}

unit XMLTestRunner;

interface
uses
  SysUtils,
  Classes,
  TestFramework;

const
   DEFAULT_FILENAME = 'dunit-report.xml';

type
  TXMLTestListener = class(TInterfacedObject, ITestListener, ITestListenerX)
  private
    FOutputFile: TextFile;
    FOutputFileName: string;
    FFileOpen: Boolean;
    FStartTime: Cardinal;
    FDtStartTime: TDateTime;
    FSuiteStack: TStringList;

    class var FConsoleOutput: string;
    class var FFailureOutput: string;
    class var FErrorOutput: string;

    procedure WriteReport(const AValue: string);
    function GetCurrentSuiteName: string;

    function Text2Sgml(const AText: string): string;
  public
    // implement the ITestListener interface
    procedure AddSuccess(ATest: ITest); virtual;
    procedure AddError(AError: TTestFailure); virtual;
    procedure AddFailure(AFailure: TTestFailure); virtual;
    function  ShouldRunTest(ATest: ITest):boolean; virtual;
    procedure StartSuite(ASuite: ITest); virtual;
    procedure EndSuite(ASuite: ITest); virtual;
    procedure StartTest(ATest: ITest); virtual;
    procedure EndTest(ATest: ITest); virtual;
    procedure TestingStarts; virtual;
    procedure TestingEnds(ATestResult: TTestResult); virtual;
    procedure Status(ATest: ITest; const Msg: string);
    procedure Warning(ATest: ITest; const Msg: string);

    constructor Create; overload;
    constructor Create(const AOutputFile: string); overload;
    destructor Destroy; override;

    class function RunTest(const ASuite: ITest; const AOutputFile: string): TTestResult; overload;
    class function RunRegisteredTests(const AOutputFile: string): TTestResult;

    property OutputFileName: string read FOutputFileName write FOutputFileName;
  end;

// Run the given test suite
function RunTest(const ASuite: ITest): TTestResult; overload;
function RunRegisteredTests: TTestResult; overload;
function TestsWereSuccessful: Boolean;
procedure RunTestsAndClose;

implementation

uses Forms, Windows;

const
  CRLF = #13#10;
  MAX_DEEP = 5;
  TrueFalse : array[Boolean] of string = ('False', 'True');


function OutputFile: string;
begin
  if (ParamCount = 2) and DirectoryExists(ExtractFilePath(ParamStr(2))) then
    Result := ParamStr(2)
  else
    Result := DEFAULT_FILENAME;
end;

function TestsWereSuccessful: Boolean;
begin
  Result := RunRegisteredTests.WasSuccessful;
end;

function RunRegisteredTests: TTestResult;
begin
  Result := TXMLTestListener.RunRegisteredTests(OutputFile);
end;

function RunTest(const ASuite: ITest): TTestResult;
begin
   Result := TXMLTestListener.RunTest(ASuite, OutputFile);
end;

procedure RunTestsAndClose;
begin
  try
    if not TestsWereSuccessful then
      Halt(1);
  except
    on E: Exception do
      Writeln(Format('%s: %s', [E.ClassName, E.Message]));
  end;
end;

{$region 'TXMLTestListener'}
class function TXMLTestListener.RunTest(
  const ASuite: ITest; const AOutputFile: string): TTestResult;
begin
   Result := TestFramework.RunTest(ASuite, [TXMLTestListener.Create(AOutputFile)]);
end;

class function TXMLTestListener.RunRegisteredTests(
  const AOutputFile: string): TTestResult;
begin
  Result := TXMLTestListener.RunTest(registeredTests, AOutputFile);
end;

constructor TXMLTestListener.Create;
begin
   Create(DEFAULT_FILENAME);
end;

constructor TXMLTestListener.Create(const AOutputFile: string);
begin
  inherited Create;
  FOutputFileName := AOutputFile;
  FSuiteStack := TStringList.Create;
  FFileOpen := False;
  FConsoleOutput := '';
  FFailureOutput := '';
  FErrorOutput := '';
end;

destructor TXMLTestListener.Destroy;
begin
  FreeAndNil(FSuiteStack);
  inherited Destroy;
end;

{Write F in the report file or on standard output if none specified}
procedure TXMLTestListener.WriteReport(const AValue: string);
begin
  if FFileOpen then
  begin
    if TTextRec(FOutputFile).Mode = fmOutput then
      writeln(FOutputFile, AValue)
    else
      writeln(AValue);
  end;
end;

procedure TXMLTestListener.AddSuccess(ATest: ITest);
begin
  if ATest.Tests.Count<=0 then
  begin
    WriteReport(
      Format(
        '<test-case name="%s%s" executed="%s" success="True" time="%1.3f" result="Pass"/>',
        [
          GetCurrentSuiteName,
          ATest.GetName,
          TrueFalse[ATest.Enabled],
          ATest.ElapsedTestTime / 1000
        ]
      )
    );
  end;
end;

procedure TXMLTestListener.AddError(AError: TTestFailure);
var
  tmp: string;
begin
  WriteReport(
    Format(
      '<test-case name="%s%s" execute="%s" success="False" time="%1.3f" result="Error">',
      [
        GetCurrentSuiteName,
        AError.FailedTest.GetName,
        TrueFalse[AError.FailedTest.Enabled],
        AError.FailedTest.ElapsedTestTime / 1000
      ]
    )
  );

  WriteReport(
    Format(
      '<failure name="%s" location="%s"/>',
      [AError.ThrownExceptionName, AError.LocationInfo]
    )
  );

  WriteReport('<message>' + Text2Sgml(AError.ThrownExceptionMessage) + '</message>');
  WriteReport('</test-case>');

  tmp := GetCurrentSuiteName + AError.FailedTest.Name;
  if Trim(AError.LocationInfo) <> EmptyStr then
    tmp := tmp + ' (' + AError.LocationInfo + ')';
  tmp := tmp + ':' + CRLF + #9 + AError.ThrownExceptionMessage + CRLF;

  FErrorOutput := FErrorOutput + CRLF + tmp;
end;

procedure TXMLTestListener.AddFailure(AFailure: TTestFailure);
var
  tmp: string;
begin
  WriteReport(
    Format(
      '<test-case name="%s%s" execute="%s" success="False" time="%1.3f" result="Failure">',
      [
        GetCurrentSuiteName,
        AFailure.FailedTest.GetName,
        TrueFalse[AFailure.FailedTest.Enabled],
        AFailure.FailedTest.ElapsedTestTime / 1000
      ]
    )
  );
  WriteReport(
    Format(
      '<failure name="%s" location="%s"/>',
      [AFailure.ThrownExceptionName, AFailure.LocationInfo]
    )
  );
  WriteReport('<message>' + Text2Sgml(AFailure.ThrownExceptionMessage) + '</message>');
  WriteReport('</test-case>');

  tmp := GetCurrentSuiteName + AFailure.FailedTest.Name;
  if Trim(AFailure.LocationInfo) <> EmptyStr then
    tmp := tmp + ' (' + AFailure.LocationInfo + ')';
  tmp := tmp + ': ' + CRLF + #9 + AFailure.ThrownExceptionMessage + CRLF;

  FFailureOutput := FFailureOutput + tmp + CRLF;
end;

procedure TXMLTestListener.StartTest(ATest: ITest);
begin
end;

procedure TXMLTestListener.EndTest(ATest: ITest);
begin
end;

procedure TXMLTestListener.TestingStarts;
begin
  FStartTime := GetTickCount;
  FDtStartTime := Now;
  FConsoleOutput := '';
  FErrorOutput := '';
  FFailureOutput := '';

  try
    if FOutputFileName<>'' then
    begin
      AssignFile(FOutputFile, FOutputFileName);
      Rewrite(FOutputFile);
      FFileOpen := true;
    end;
  except
    on E:EInOutError do
     FFileOpen := False;
  end;

  WriteReport('<?xml version="1.0" encoding="ISO-8859-1" standalone="yes" ?>');
  WriteReport(
    Format(
      '<test-results total="%d" notrun="%d" date="%s" time="%s">',
      [
        RegisteredTests.CountTestCases,
        RegisteredTests.CountTestCases - RegisteredTests.CountEnabledTestCases,
        DateToStr(Now),
        TimeToStr(Now)
      ]
    )
  );
end;

procedure TXMLTestListener.TestingEnds(ATestResult: TTestResult);
var
  RunTime : Double;
  SuccessRate : Integer;
  RunCount, ErrorCount, FailureCount: Integer;
begin
  RunTime := (GetTickCount - FStartTime) / 1000;

  try
    RunCount := ATestResult.RunCount;
  except
    RunCount := 0;
  end;

  try
    if not ATestResult.WasSuccessful then
      FailureCount := ATestResult.FailureCount
    else
      FailureCount := 0;
  except
    FailureCount := 0;
  end;

  try
    if not ATestResult.WasSuccessful then
      ErrorCount := ATestResult.ErrorCount
    else
      ErrorCount := 0;
  except
    ErrorCount := 0;
  end;

  if RunCount > 0 then
    SuccessRate :=  Trunc(((RunCount - FailureCount - ErrorCount) / RunCount) *100)
  else
    SuccessRate := 100;

  WriteReport('<statistics>' + CRLF +
                '<stat name="tests" value="' + IntToStr(RunCount) + '" />' + CRLF +
                '<stat name="failures" value="' + IntToStr(FailureCount) + '" />' + CRLF +
                '<stat name="errors" value="' + IntToStr(ErrorCount) + '" />' + CRLF +
                '<stat name="success-rate" value="' + IntToStr(SuccessRate) + '%" />' + CRLF +
                '<stat name="started-at" value="' + DateTimeToStr(FDtStartTime) + '" />' + CRLF +
                '<stat name="finished-at" value="' + DateTimeToStr(now) + '" />' + CRLF +
                Format('<stat name="runtime" value="%1.3f"/>', [RunTime]) + CRLF +
              '</statistics>' + CRLF +
              '</test-results>');

  if FFileOpen and (TTextRec(FOutputFile).Mode = fmOutput) then
    Close(FOutputFile);

  FConsoleOutput := 'Run: ' + IntToStr(RunCount) +
                    ' / Failures: ' + IntToStr(FailureCount) +
                    ' / Errors: ' + IntToStr(ErrorCount);

  if ErrorCount > 0 then
    FConsoleOutput := FConsoleOutput + CRLF + 'Errors:' + CRLF + Trim(FErrorOutput);
  if FailureCount > 0 then
    FConsoleOutput := FConsoleOutput + CRLF + 'Failures:' + CRLF + Trim(FFailureOutput);

  FConsoleOutput := Trim(FConsoleOutput);
  Writeln(FConsoleOutput);
end;

procedure TXMLTestListener.Status(ATest: ITest; const Msg: string);
begin
  WriteReport(Format('INFO: %s: %s', [ATest.Name, Msg]));
end;

procedure TXMLTestListener.Warning(ATest: ITest; const Msg: string);
begin
  WriteReport(Format('WARNING: %s: %s', [ATest.Name, Msg]));
end;

function TXMLTestListener.ShouldRunTest(ATest: ITest): Boolean;
begin
  Result := ATest.Enabled;
  if not Result then
    WriteReport(
      Format(
        '<test-case name="%s%s" executed="False"/>',
        [GetCurrentSuiteName, ATest.GetName]
      )
    );
end;

procedure TXMLTestListener.EndSuite(ASuite: ITest);
begin
  if CompareText(ASuite.Name, ExtractFileName(Application.ExeName)) = 0 then
    Exit;

  WriteReport('</results>');
  WriteReport('</test-suite>');
  FSuiteStack.Delete(0);
end;

procedure TXMLTestListener.StartSuite(ASuite: ITest);
var
  s: string;
begin
  if CompareText(ASuite.Name, ExtractFileName(Application.ExeName)) = 0 then
    Exit;

  s := GetCurrentSuiteName + ASuite.Name;
  WriteReport(
    Format(
      '<test-suite name="%s" total="%d" notrun="%d">',
      [
        s,
        ASuite.CountTestCases,
        ASuite.CountTestCases - ASuite.CountEnabledTestCases
      ]
    )
  );

  FSuiteStack.Insert(0, ASuite.Name);
  WriteReport('<results>');
end;

function TXMLTestListener.GetCurrentSuiteName: string;
var
  StackIndex: Integer;
begin
  Result := '';

  for StackIndex := 0 to FSuiteStack.Count - 1 do
    Result := FSuiteStack[StackIndex] + '.' + Result;
end;

function TXMLTestListener.Text2Sgml(const AText: string): string;
begin
  Result := StringReplace(AText, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;
{$endregion 'TXMLTestListener'}

end.
