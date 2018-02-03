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
  SysUtils, I_Logger;

type
  TLoggerTextFile = class(TInterfacedObject, ILogger)
  private
    FTextFile: TextFile;
  public
    constructor Create(const AFileName: TFileName);
    destructor Destroy; override;

    procedure Log(const AMessage: string);
  end;

implementation

uses IOUtils;

{ TLoggerTextFile }

constructor TLoggerTextFile.Create(const AFileName: TFileName);
begin
  inherited Create;

  ForceDirectories(TPath.GetDirectoryName(TPath.GetFullPath(AFileName)));
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
