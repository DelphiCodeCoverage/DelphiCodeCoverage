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
  JclStringLists,
  I_LogManager,
  I_Logger;

type
  TLogManager = class(TInterfacedObject, ILogManager)
  private
    FLoggers : IJclStringList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Log(const AMessage : string);

    procedure AddLogger(const LoggerName : string; const ALogger : ILogger);
  end;

implementation


{ TLoggerManager }

constructor TLogManager.Create;
begin
  Inherited;
  FLoggers := TJclStringList.Create;
end;

destructor TLogManager.Destroy;
begin
  FLoggers := nil;

  inherited;
end;

procedure TLogManager.AddLogger(const LoggerName : string; const ALogger : ILogger);
begin
  FLoggers.KeyInterface[LoggerName] := ALogger;
end;

procedure TLogManager.Log(const AMessage: string);
var
  lp : Integer;
begin
  for lp := 0 to Pred(FLoggers.Count) do
  begin
    ILogger(FLoggers.Interfaces[lp]).Log(AMessage);
  end;
end;

end.

