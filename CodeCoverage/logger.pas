(* ************************************************************ *)
(* Delphi Code Coverage                                         *)
(*                                                              *)
(* A quick hack of a Code Coverage Tool for Delphi 2010         *)
(* by Christer Fahlgren                                         *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1                  *)
(* ************************************************************ *)
unit logger;

interface

type
  TLogger = class
  private
    myFile: TextFile;

  public
    procedure Log(msg: string);
    destructor Destroy; override;
    constructor Create(filename: string);
  end;

var
  Log: TLogger;

implementation

uses sysutils;

constructor TLogger.Create(filename: string);
begin
  AssignFile(myFile, filename);
  if Fileexists(filename) then
    rewrite(myFile)
  else
    rewrite(myFile);
end;

procedure TLogger.Log(msg: string);
begin
  WriteLn(myFile, msg);
  Flush(myFile);
end;

destructor TLogger.Destroy;
begin
  CloseFile(myFile);
end;

initialization

Log := TLogger.Create('debuglog.txt');

finalization

Log.free;

end.
