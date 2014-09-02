(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit LogManager;

interface

{$INCLUDE CodeCoverage.inc}

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

