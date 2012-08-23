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

type
  TMergable = class
    procedure LoadFromFile(var aFile: File); virtual; abstract;
    function ToString(): String; override; abstract;
    function GetEntryLength(): Int64; virtual; abstract;
    function GetEntryType(): Byte; virtual; abstract;
    procedure WriteToFile(var aFile: File); virtual; abstract;
  end;

implementation

end.
