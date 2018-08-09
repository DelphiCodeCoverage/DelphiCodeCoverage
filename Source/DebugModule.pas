(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit DebugModule;

interface

uses
  System.Classes,
  I_DebugModule,
  JCLDebug;

type
  TDebugModule = class(TInterfacedObject, IDebugModule)
  strict private
    FName: String;
    FBase: HMODULE;
    FSize: Cardinal;
    FMapScanner: TJCLMapScanner;
  public
    function Name: string;
    function Base: HMODULE;
    function Size: Cardinal;
    function MapScanner: TJCLMapScanner;

    constructor Create(
      const AName: string;
      const ABase: HMODULE;
      const ASize: Cardinal;
      const AMapScanner: TJCLMapScanner);
  end;

implementation

constructor TDebugModule.Create(
  const AName: string;
  const ABase: HMODULE;
  const ASize: Cardinal;
  const AMapScanner: TJCLMapScanner);
begin
  inherited Create;
  FName := AName;
  FBase := ABase;
  FSize := ASize;
  FMapScanner := AMapScanner;
end;

function TDebugModule.Name: string;
begin
  Result := FName;
end;

function TDebugModule.Base: HMODULE;
begin
  Result := FBase;
end;

function TDebugModule.Size: Cardinal;
begin
  Result := FSize;
end;

function TDebugModule.MapScanner: TJCLMapScanner;
begin
  Result := FMapScanner;
end;

end.
