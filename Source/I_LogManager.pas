(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit I_LogManager;

interface

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
  Winapi.Windows,
  System.SysUtils;

function LastErrorInfo: string;
var
  LastError: DWORD;
begin
  LastError := GetLastError;
  Result := IntToStr(LastError) +
            '(' + IntToHex(LastError, 8) + ') -> ' +
            SysErrorMessage(LastError);
end;

end.
