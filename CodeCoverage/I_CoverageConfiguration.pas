(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_CoverageConfiguration;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes;

type
  ICoverageConfiguration = interface
    procedure ParseCommandLine();

    function GetApplicationParameters        : string;
    function GetExeFileName                  : string;
    function GetMapFileName                  : string;
    function GetOutputDir                    : string;
    function GetSourceDir                    : string;
    function GetUnits                        : TStrings;
    function GetDebugLogFile                 : string;
    function UseApiDebug                     : boolean;
    function IsComplete(var reason : string) : Boolean;
  end;

const
  ESCAPE_CHARACTER : char = '^';
  DEFULT_DEBUG_LOG_FILENAME = 'Delphi-Code-Coverage-Debug.log';

implementation

end.
