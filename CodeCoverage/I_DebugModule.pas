(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_DebugModule;

interface

uses Windows, JCLDebug;

type
   IDebugModule = interface
     function Name: string;
     function Base: HMODULE;
     function Size: Cardinal;
     function MapScanner: TJCLMapScanner;
  end;

implementation
end.
