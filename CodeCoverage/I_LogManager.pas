(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_LogManager;

interface

{$INCLUDE CodeCoverage.inc}

uses
  I_Logger;

type
  ILogManager = interface
    procedure Log(const AMessage : string);

    procedure AddLogger(const ALogger : ILogger);
  end;

function LastErrorInfo: string;

implementation

uses
  Windows,
  SysUtils;

function LastErrorInfo: string;
var
  LastError: DWORD;
begin
  LastError := GetLastError;
  Result := IntToStr(LastError) +
            '(' + IntToHex(LastError, 8) + ') -> ' +
            SysUtils.SysErrorMessage(LastError);
end;

end.
