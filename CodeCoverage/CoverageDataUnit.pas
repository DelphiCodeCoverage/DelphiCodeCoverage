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
  MergableUnit,
  Generics.Collections,
  FileHelper;

type

  TDataHolder = class
  private
    FClassName: string;
    FCoverageArray: TMultiBooleanArray;
    FStamp: Int64;
    FMultiBooleanArray: TMultiBooleanArray;
    FTheClassName: string;
  public
    property Stamp: Int64 read FStamp;
    property MultiBooleanArray: TMultiBooleanArray read FMultiBooleanArray;
    property TheClassName: string read FTheClassName;

    constructor Create(
      const AClassName: string;
      const AStamp: Int64;
      var AMultiBooleanArray: TMultiBooleanArray);
  end;

  TEmmaCoverageData = class(TMergable)
  private
    FClassList: TList<TDataHolder>;
  public
    procedure LoadFromFile(var AFile: File); override;
    function ToString: string; override;
    constructor Create;
    destructor Destroy; override;
    function GetEntryLength: Int64; override;
    function GetEntryType: Byte; override;
    procedure WriteToFile(var AFile: File); override;
    procedure Add(const ADataHolder: TDataHolder);
  end;

implementation

uses sysutils;

constructor TDataHolder.Create(
  const AClassName: string;
  const AStamp: Int64;
  var AMultiBooleanArray: TMultiBooleanArray);
begin
  inherited Create;

  FClassName := AClassName;
  FCoverageArray := AMultiBooleanArray;
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

procedure TEmmaCoverageData.LoadFromFile(var AFile: File);
var
  Size: Integer;
  Coverage: TMultiBooleanArray;
  I: Integer;
  Length: Integer;
  ClassVMName: String;
  Stamp: Int64;
  C: Integer;
begin
  Size := readInteger(AFile);

  for I := 0 to Size - 1 do
  begin
    ClassVMName := readUTF(AFile);
    Stamp := readInt64(AFile);
    Length := readInteger(AFile);
    SetLength(Coverage, Length);
    for C := 0 to Length - 1 do
      readBooleanArray(AFile, Coverage[C]);
    FClassList.Add(TDataHolder.Create(ClassVMName, Stamp, Coverage));
  end;
end;

procedure TEmmaCoverageData.WriteToFile(var AFile: File);
var
  I: Integer;
  DataHolder: TDataHolder;
begin
  writeInteger(aFile, FClassList.Count);
  for DataHolder in FClassList do
  begin
    writeUTF(aFile, DataHolder.TheClassName);
    writeInt64(aFile, DataHolder.Stamp);
    writeInteger(aFile, Length(DataHolder.MultiBooleanArray));
    for I := 0 to High(DataHolder.MultiBooleanArray) do
      writeBooleanArray(aFile, DataHolder.MultiBooleanArray[I]);
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
      BoolArr := DataHolder.MultiBooleanArray;
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
    Result := Result + getUtf8Length(DataHolder.TheClassName);
    Result := Result + sizeof(DataHolder.Stamp);
    Result := Result + sizeof(Integer);
    for i := 0 to High(DataHolder.MultiBooleanArray) do
      Result := Result + FileHelper.getEntryLength(DataHolder.MultiBooleanArray[i]);
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
