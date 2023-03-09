(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)
unit ClassInfoUnitTest;

interface

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
    procedure TestGetProcedureName;
    procedure TestGetClassName;
 end;


implementation

procedure TClassInfoUnitTest.TestClassInfo;
var cinfo : TClassInfo;
begin
  cinfo:= TClassInfo.Create('Module','MyClass');
  cinfo.ensureProcedure('TestProcedure');
end;

procedure TClassInfoUnitTest.TestGetProcedureName;
begin
  CheckEquals(
    'Bar',
    TModuleList.GetProcedureName('foo', 'foo.Bar'),
    'foo.Bar should have Bar as procedure name'
  );
  CheckEquals(
    'Baz',
    TModuleList.GetProcedureName('foo', 'foo.Bar.Baz'),
    'foo.Bar.Baz should have Baz as procedure name'
  );
  CheckEquals(
    'Baz',
    TModuleList.GetProcedureName('foo', 'foo.Bar.Baz$0'),
    'foo.Bar.Baz$0 should have Baz as procedure name'
  );
  CheckEquals(
    '',
    TModuleList.GetProcedureName('foo', 'foo.Bar.Baz$ActRec.$0$Body'),
    'foo.Bar.Baz$ActRec.$0$Body anonymous function should have no procedure name'
  );
  CheckEquals(
    'Boo',
    TModuleList.GetProcedureName('foo', 'foo.Bar.Baz.Boo'),
    'foo.Bar.Baz.Boo should have Boo as procedure name'
  );
  CheckEquals(
    'Boo',
    TModuleList.GetProcedureName('foo', 'foo.Bar.Baz.Boo$0'),
    'foo.Bar.Baz.Boo$0 should have Boo as procedure name'
  );
  CheckEquals(
    '',
    TModuleList.GetProcedureName('foo', 'foo.Bar.Baz.Boo$ActRec.$0$Body'),
    'foo.Bar.Baz.Boo$ActRec.$0$Body anonymous function should have no procedure name'
  );
end;

procedure TClassInfoUnitTest.TestGetClassName;
begin
  CheckEquals(
    'Bar',
    TModuleList.GetClassName('foo', 'foo.Bar'),
    'foo.Bar should have Bar as class name'
  );
  CheckEquals(
    'Bar',
    TModuleList.GetClassName('foo', 'foo.Bar.Baz'),
    'foo.Bar.Baz should have Bar as class name'
  );
  CheckEquals(
    'Bar',
    TModuleList.GetClassName('foo', 'foo.Bar.Baz$0'),
    'foo.Bar.Baz$0 should have Bar as class name'
  );
  CheckEquals(
    'Bar.Baz$ActRec',
    TModuleList.GetClassName('foo', 'foo.Bar.Baz$ActRec.$0$Body'),
    'foo.Bar.Baz$ActRec.$0$Body anonymous function should have Bar as class name'
  );
  CheckEquals(
    'Bar.Baz',
    TModuleList.GetClassName('foo', 'foo.Bar.Baz.Boo'),
    'foo.Bar.Baz.Boo should have Bar.Baz as class name'
  );
  CheckEquals(
    'Bar.Baz',
    TModuleList.GetClassName('foo', 'foo.Bar.Baz.Boo$0$Body'),
    'foo.Bar.Baz.Boo$0$Body should have Bar.Baz as class name'
  );
  CheckEquals(
    'Bar.Baz',
    TModuleList.GetClassName('foo', 'foo.Bar.Baz.$0$Body'),
    'foo.Bar.Baz.$0$Body anonymous function should have Bar as class name'
  );
end;

//==============================================================================
initialization
  RegisterTest(TClassInfoUnitTest.Suite);


end.
