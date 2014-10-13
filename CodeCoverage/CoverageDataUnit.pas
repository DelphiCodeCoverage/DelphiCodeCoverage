(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit CoverageDataUnit;

interface

uses
  Classes,
  Generics.Collections,
  MergableUnit,
  FileHelper;

type

  TDataHolder = class
  private
    FStamp: Int64;
    FCoverageArray: TMultiBooleanArray;
    FTheClassName: string;
  public
    property Stamp: Int64 read FStamp;
    property CoverageArray: TMultiBooleanArray read FCoverageArray;
    property TheClassName: string read FTheClassName;

    constructor Create(
      const ATheClassName: string;
      const AStamp: Int64;
      const ACoverageArray: TMultiBooleanArray);
  end;

  TEmmaCoverageData = class(TMergable)
  private
    FClassList: TList<TDataHolder>;
  public
    procedure LoadFromFile(const DataInput: IEmmaDataInput); override;
    function ToString: string; override;
    constructor Create;
    destructor Destroy; override;
    function GetEntryLength: Int64; override;
    function GetEntryType: Byte; override;
    procedure WriteToFile(DataOutput: IEmmaDataOutput); override;
    procedure Add(const ADataHolder: TDataHolder);
  end;

implementation

uses SysUtils;

constructor TDataHolder.Create(
  const ATheClassName: string;
  const AStamp: Int64;
  const ACoverageArray: TMultiBooleanArray);
begin
  inherited Create;

  FTheClassName := ATheClassName;
  FCoverageArray := ACoverageArray;
  FStamp := AStamp;
end;

constructor TEmmaCoverageData.Create;
begin
  inherited Create;

  FClassList := TList<TDataHolder>.Create;
end;

destructor TEmmaCoverageData.Destroy;
var
  CurrentDataHolder: TDataHolder;
begin
  for CurrentDataHolder in FClassList do
    CurrentDataHolder.Free;

  FClassList.Destroy;
  inherited Destroy;
end;

procedure TEmmaCoverageData.LoadFromFile(const DataInput: IEmmaDataInput);
var
  Size: Integer;
  Coverage: TMultiBooleanArray;
  I: Integer;
  Length: Integer;
  ClassVMName: String;
  Stamp: Int64;
  C: Integer;
begin
  Size := DataInput.ReadInteger;

  for I := 0 to Size - 1 do
  begin
    ClassVMName := DataInput.ReadUTF;
    Stamp := DataInput.ReadInt64;
    Length := DataInput.ReadInteger;
    SetLength(Coverage, Length);
    for C := 0 to Length - 1 do
      Coverage[C] := DataInput.ReadBooleanArray;
    FClassList.Add(TDataHolder.Create(ClassVMName, Stamp, Coverage));
  end;
end;

procedure TEmmaCoverageData.WriteToFile(DataOutput: IEmmaDataOutput);
var
  I: Integer;
  DataHolder: TDataHolder;
begin
  DataOutput.WriteInteger(FClassList.Count);
  for DataHolder in FClassList do
  begin
    DataOutput.WriteUTF(DataHolder.TheClassName);
    DataOutput.WriteInt64(DataHolder.Stamp);
    DataOutput.WriteInteger(Length(DataHolder.CoverageArray));
    for I := 0 to High(DataHolder.CoverageArray) do
      DataOutput.WriteBooleanArray(DataHolder.CoverageArray[I]);
  end;
end;

function TEmmaCoverageData.ToString: string;
var
  DataHolder: TDataHolder;
  BoolArr: TMultiBooleanArray;
  i, j: Integer;
begin
  Result := '';
  for DataHolder in FClassList do
  begin
    if (DataHolder <> nil) then
    begin
      Result := Result + ' EC[ class:' + DataHolder.TheClassName + ' ';
      Result := Result + ' stamp:' + IntToStr(DataHolder.Stamp) + ' ';
      BoolArr := DataHolder.CoverageArray;
      for i := 0 to Length(BoolArr) - 1 do
      begin
        Result := Result + ' Method:' + IntToStr(i);
        for j := 0 to Length(BoolArr[i]) - 1 do
        begin
          if (BoolArr[i])[j] then
            Result := Result + ' block:' + IntToStr(j) + ': covered '
          else
            Result := Result + ' block:' + IntToStr(j) + ': not covered ';
        end;
      end;
      Result := Result + ']';
    end;
  end;
end;

function TEmmaCoverageData.GetEntryLength: Int64;
var
  DataHolder: TDataHolder;
  i: Integer;
begin
  Result := 0;
  Result := Result + SizeOf(Integer);

  for DataHolder in FClassList do
  begin
    Result := Result + FileHelper.GetUtf8Length(DataHolder.TheClassName);
    Result := Result + SizeOf(DataHolder.Stamp);
    Result := Result + SizeOf(Integer);
    for i := 0 to High(DataHolder.CoverageArray) do
      Result := Result + FileHelper.GetEntryLength(DataHolder.CoverageArray[i]);
  end;
end;

function TEmmaCoverageData.GetEntryType: Byte;
begin
  Result := 1;
end;

procedure TEmmaCoverageData.Add(const ADataHolder: TDataHolder);
begin
  FClassList.Add(ADataHolder);
end;

end.
