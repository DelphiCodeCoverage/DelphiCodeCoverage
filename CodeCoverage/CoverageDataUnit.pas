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

uses MergableUnit, Generics.Collections, FileHelper;

type

  TDataHolder = class
  private
    fClassName: String;
    fCoverageArray: TMultiBooleanArray;
    fStamp: Int64;
  public
    constructor Create(AClassName: String; AStamp: Int64;
      var AMultiBooleanArray: TMultiBooleanArray);
    function getStamp(): Int64;
    function getMultiBooleanArray(): TMultiBooleanArray;
    function getClassName(): String;

  end;

  TEmmaCoverageData = class(TMergable)
  private
    fClassList: TList<TDataHolder>;
  public
    procedure loadFromFile(var aFile: File); override;
    function toString(): String; override;
    constructor Create;
    destructor Destroy; override;
    function getEntryLength(): Int64; override;
    function getEntryType: Byte; override;
    procedure writeToFile(var aFile: File); override;
    procedure add(ADataHolder: TDataHolder);
  end;

implementation

uses sysutils;

constructor TDataHolder.Create(AClassName: String; AStamp: Int64;
  var AMultiBooleanArray: TMultiBooleanArray);
begin
  fClassName := AClassName;
  fCoverageArray := AMultiBooleanArray;
  fStamp := AStamp;
end;

function TDataHolder.getStamp(): Int64;
begin
  result := fStamp;
end;

function TDataHolder.getClassName: String;
begin
  result := fClassName;
end;

function TDataHolder.getMultiBooleanArray(): TMultiBooleanArray;
begin
  result := fCoverageArray;
end;

constructor TEmmaCoverageData.Create;
begin
  fClassList := TList<TDataHolder>.Create();
end;

destructor TEmmaCoverageData.Destroy;
begin
  fClassList.Destroy;
end;

procedure TEmmaCoverageData.loadFromFile(var aFile: File);
var
  size: Integer;
  coverage: TMultiBooleanArray;
  i: Integer;
  length: Integer;
  classVMName: String;
  stamp: Int64;
  c: Integer;
begin
  size := readInteger(aFile);
  for i := 0 to size - 1 do
  begin
    classVMName := readUTF(aFile);
    stamp := readInt64(aFile);
    length := readInteger(aFile);
    setlength(coverage, length);
    for c := 0 to length - 1 do
      readBooleanArray(aFile, coverage[c]);
    fClassList.add(TDataHolder.Create(classVMName, stamp, coverage));
  end;

end;

procedure TEmmaCoverageData.writeToFile(var aFile: File);
var
  i: Integer;
  dh: TDataHolder;
  enum: TList<TDataHolder>.TEnumerator;
begin
  writeInteger(aFile, fClassList.Count);
  enum := fClassList.GetEnumerator();
  while (enum.MoveNext) do
  begin
    dh := enum.Current;
    writeUTF(aFile, dh.getClassName());
    writeInt64(aFile, dh.getStamp());
    writeInteger(aFile, length(dh.getMultiBooleanArray()));
    for i := 0 to high(dh.getMultiBooleanArray) do
    begin
      writeBooleanArray(aFile, dh.getMultiBooleanArray[i]);
    end;
  end;
end;

function TEmmaCoverageData.toString(): String;
var
  dh: TDataHolder;
  boolArr: TMultiBooleanArray;
  i, j: Integer;
begin
  result := '';
  for dh in fClassList do
  begin
    if (dh <> nil) then
    begin
      result := result + ' EC[ class:' + dh.getClassName() + ' ';
      result := result + ' stamp:' + IntToStr(dh.getStamp()) + ' ';
      boolArr := dh.getMultiBooleanArray;
      for i := 0 to length(boolArr) - 1 do
      begin
        result := result + ' Method:' + IntToStr(i);
        for j := 0 to length(boolArr[i]) - 1 do
        begin
          if (boolArr[i])[j] then
          begin
            result := result + ' block:' + IntToStr(j) + ': covered ';
          end
          else
          begin
            result := result + ' block:' + IntToStr(j) + ': not covered ';
          end;
        end;
      end;
      result := result + ']';

    end;
  end;

end;

function TEmmaCoverageData.getEntryLength(): Int64;
var
  size: Integer;
  dh: TDataHolder;
  i: Integer;
  enum: TList<TDataHolder>.TEnumerator;
begin
  size := 0;
  size := size + sizeof(Integer);
  enum := fClassList.GetEnumerator();
  while (enum.MoveNext) do
  begin
    dh := enum.Current;
    size := size + getUtf8Length(dh.getClassName());
    size := size + sizeof(dh.getStamp);
    size := size + sizeof(Integer);
    for i := 0 to high(dh.getMultiBooleanArray) do
    begin
      size := size + FileHelper.getEntryLength(dh.getMultiBooleanArray[i]);
    end;
  end;
  result := size;
end;

function TEmmaCoverageData.getEntryType: Byte;
begin
  result := 1;
end;

procedure TEmmaCoverageData.add(ADataHolder: TDataHolder);
begin
  fClassList.add(ADataHolder);
end;

end.
