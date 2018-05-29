(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit LogManager;

interface

uses
  Generics.Collections,
  I_LogManager,
  I_Logger;

type
  TLogManager = class(TInterfacedObject, ILogManager)
  private
    FLoggers: TList<ILogger>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Log(const AMessage : string);

    procedure AddLogger(const ALogger : ILogger);
  end;

implementation


{ TLoggerManager }

constructor TLogManager.Create;
begin
  inherited;
  FLoggers := TList<ILogger>.Create;
end;

destructor TLogManager.Destroy;
begin
  FLoggers.Free;
  inherited;
end;

procedure TLogManager.AddLogger(const ALogger: ILogger);
begin
  FLoggers.Add(ALogger);
end;

procedure TLogManager.Log(const AMessage: string);
var
  Logger: ILogger;
begin
  for Logger in FLoggers do
    Logger.Log(AMessage);
end;

end.

