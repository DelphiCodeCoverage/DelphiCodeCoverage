(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit DebugModule;

interface

uses
  Classes,
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

function TDebugModule.Name;
begin
  Result := FName;
end;

function TDebugModule.Base;
begin
  Result := FBase;
end;

function TDebugModule.Size: Cardinal;
begin
  Result := FSize;
end;

function TDebugModule.MapScanner;
begin
  Result := FMapScanner;
end;

end.
