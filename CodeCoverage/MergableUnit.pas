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
    procedure loadFromFile(var aFile: File); virtual; abstract;
    function ToString(): String; virtual; abstract;
    function getEntryLength(): Int64; virtual; abstract;
    function getEntryType(): Byte; virtual; abstract;
    procedure writeToFile(var aFile: File); virtual; abstract;
  end;

implementation

end.
