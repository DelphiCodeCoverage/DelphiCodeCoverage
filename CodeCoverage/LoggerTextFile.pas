(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit LoggerTextFile;

interface

{$INCLUDE CodeCoverage.inc}

uses
  I_Logger;

type
  TLoggerTextFile = class(TInterfacedObject, ILogger)
  private
    FTextFile: TextFile;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;

    procedure Log(const AMessage: string);
  end;

implementation

{ TLoggerTextFile }

constructor TLoggerTextFile.Create(const AFileName: string);
begin
  inherited Create;

  AssignFile(FTextFile, AFileName);
  ReWrite(FTextFile);
end;

destructor TLoggerTextFile.Destroy;
begin
  CloseFile(FTextFile);

  inherited;
end;

procedure TLoggerTextFile.Log(const AMessage: string);
begin
  WriteLn(FTextFile, AMessage);
  Flush(FTextFile);
end;

end.
