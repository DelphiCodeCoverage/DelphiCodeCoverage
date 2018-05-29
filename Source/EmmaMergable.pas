(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit EmmaMergable;

interface

uses
  EmmaFileHelper;

type
  TMergable = class abstract
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
