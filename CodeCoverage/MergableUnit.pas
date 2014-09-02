(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit MergableUnit;

interface

uses
  FileHelper;

type
  TMergable = class
  protected
    function GetEntryLength: Int64; virtual; abstract;
    function GetEntryType: Byte; virtual; abstract;
  public
    property EntryLength: Int64 read GetEntryLength;
    property EntryType: Byte read GetEntryType;

    function ToString: string; override; abstract;

    procedure LoadFromFile(const DataInput: IEmmaDataInput); virtual; abstract;
    procedure WriteToFile(DataOutput: IEmmaDataOutput); virtual; abstract;
  end;

implementation

end.
