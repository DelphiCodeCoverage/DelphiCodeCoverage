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
     function getName():String;
     function getBase():HMODULE;
     function getSize(): Cardinal;
     function getJCLMapScanner() : TJCLMapScanner;
  end;

implementation
end.
