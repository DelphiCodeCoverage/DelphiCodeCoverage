(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit LoggerAPI;

interface

{$INCLUDE CodeCoverage.inc}

uses
  I_Logger;

type
  TLoggerAPI = class(TInterfacedObject, ILogger)
  public
    procedure Log(const AMessage: string);
  end;

implementation

uses
  Windows;

{ TLoggerAPI }

procedure TLoggerAPI.Log(const AMessage: string);
begin
  OutputDebugString(PChar(AMessage));
end;

end.
