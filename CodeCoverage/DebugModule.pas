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

uses classes, I_DebugModule, JCLDebug;

type
  TDebugModule = class(TInterfacedObject, IDebugModule)
  public
    function getName(): String;
    function getBase(): HMODULE;
    function getSize(): Cardinal;
    function getJCLMapScanner(): TJCLMapScanner;
    constructor Create(name: String; base: HMODULE; const size: Cardinal;
      const mapScanner: TJCLMapScanner);
  private
    fName: String;
    fBase: HMODULE;
    fSize: Cardinal;
    fJCLMapScanner: TJCLMapScanner;
  end;

implementation

constructor TDebugModule.Create(name: String; base: HMODULE;
  const size: Cardinal; const mapScanner: TJCLMapScanner);
begin
  fName := name;
  fBase := base;
  fSize := size;
  fJCLMapScanner := mapScanner;
end;

function TDebugModule.getName;
begin
  result := fName;
end;

function TDebugModule.getBase;
begin
  result := fBase;
end;

function TDebugModule.getSize(): Cardinal;
begin
  result := fSize;
end;

function TDebugModule.getJCLMapScanner;
begin
  result := fJCLMapScanner;
end;

end.
