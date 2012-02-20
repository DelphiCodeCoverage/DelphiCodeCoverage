unit ClassInfoUnitTest;

interface
{$INCLUDE ..\CodeCoverage.inc}


uses
  Classes,
  SysUtils,
  TestFramework,
  ClassInfoUnit;

  type

  TClassInfoUnitTest = class(TTestCase)
  private

  published
    procedure TestClassInfo;
 end;


implementation

procedure TClassInfoUnitTest.TestClassInfo;
var cinfo : TClassInfo;
begin
  cinfo:= TClassInfo.Create('Module','MyClass');
  cinfo.ensureProcedure('TestProcedure');


end;

//==============================================================================
initialization
  RegisterTest(TClassInfoUnitTest.Suite);


end.
