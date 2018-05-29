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
