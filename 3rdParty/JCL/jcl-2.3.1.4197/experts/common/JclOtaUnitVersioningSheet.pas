{**************************************************************************************************}
{                                                                                                  }
{ Project JEDI Code Library (JCL)                                                                  }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is JclOtaUnitVersioningSheet.pas.                                              }
{                                                                                                  }
{ The Initial Developer of the Original Code is Florent Ouchet                                     }
{         <outchy att users dott sourceforge dott net>                                             }
{ Portions created by Florent Ouchet are Copyright (C) of Florent Ouchet. All rights reserved.     }
{                                                                                                  }
{ Contributors:                                                                                    }
{                                                                                                  }
{**************************************************************************************************}
{                                                                                                  }
{ Last modified: $Date:: 2009-09-14 18:00:50 +0200 (lun., 14 sept. 2009)                         $ }
{ Revision:      $Rev:: 3012                                                                     $ }
{ Author:        $Author:: outchy                                                                $ }
{                                                                                                  }
{**************************************************************************************************}

unit JclOtaUnitVersioningSheet;

{$I jcl.inc}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  JclUnitVersioning,
  Dialogs, ComCtrls, StdCtrls;

type
  TJclOtaUnitVersioningFrame = class(TFrame)
    MemoUnitVersioning: TMemo;
    ButtonCopyToClipboard: TButton;
    ButtonSaveAsText: TButton;
    SaveDialogText: TSaveDialog;
    procedure ButtonCopyToClipboardClick(Sender: TObject);
    procedure ButtonSaveAsTextClick(Sender: TObject);
  private
  public
    constructor Create(AOwner: TComponent); override;
  end;

{$IFDEF UNITVERSIONING}
const
  UnitVersioning: TUnitVersionInfo = (
    RCSfile: '$URL: https://jcl.svn.sourceforge.net:443/svnroot/jcl/tags/JCL-2.3-Build4197/jcl/experts/common/JclOtaUnitVersioningSheet.pas $';
    Revision: '$Revision: 3012 $';
    Date: '$Date: 2009-09-14 18:00:50 +0200 (lun., 14 sept. 2009) $';
    LogPath: 'JCL\experts\common';
    Extra: '';
    Data: nil
    );
{$ENDIF UNITVERSIONING}

implementation

{$R *.dfm}

uses
  ActnList, Menus,
  ToolsApi,
  JclBase, JclFileUtils, JclUnitVersioningProviders,
  JclOtaConsts, JclOtaResources, JclOtaUtils;

procedure TJclOtaUnitVersioningFrame.ButtonCopyToClipboardClick(
  Sender: TObject);
begin
  MemoUnitVersioning.SelectAll;
  MemoUnitVersioning.CopyToClipboard;
end;

procedure TJclOtaUnitVersioningFrame.ButtonSaveAsTextClick(Sender: TObject);
begin
  if SaveDialogText.Execute then
    MemoUnitVersioning.Lines.SaveToFile(SaveDialogText.FileName);
end;

constructor TJclOtaUnitVersioningFrame.Create(AOwner: TComponent);
var
  UnitVersioning: TUnitVersioning;
  UnitVersioningModule: TUnitVersioningModule;
  UnitVersion: TUnitVersion;
  I, J: Integer;
  LongFileName: string;
begin
  inherited Create(AOwner);
  ButtonCopyToClipboard.Caption := LoadResString(@RsCopyToClipboard);
  ButtonSaveAsText.Caption := LoadResString(@RsSaveAsText);
  
  UnitVersioning := GetUnitVersioning;
  UnitVersioning.RegisterProvider(TJclDefaultUnitVersioningProvider);
  for I := 0 to Pred(UnitVersioning.ModuleCount) do
    UnitVersioning.LoadModuleUnitVersioningInfo(UnitVersioning.Modules[I].Instance);
  MemoUnitVersioning.Lines.BeginUpdate;
  try
    MemoUnitVersioning.Lines.Clear;
    MemoUnitVersioning.Lines.Add(Format('JCL %d.%d.%d.%d', [JclVersionMajor, JclVersionMinor, JclVersionRelease, JclVersionBuild]));
    for I := 0 to Pred(UnitVersioning.ModuleCount) do
    begin
      UnitVersioningModule := UnitVersioning.Modules[I];
      MemoUnitVersioning.Lines.Add(Format('%s [%d units]', [GetModulePath(UnitVersioningModule.Instance), UnitVersioningModule.Count]));
      for J := 0 to Pred(UnitVersioningModule.Count) do
      begin
        UnitVersion := UnitVersioningModule.Items[J];
        LongFileName := UnitVersion.LogPath;
        if LongFileName <> '' then
          LongFileName := PathAddSeparator(LongFileName);
        LongFileName := LongFileName + UnitVersion.RCSfile;
        MemoUnitVersioning.Lines.Add(Format('%s  %s  %s', [LongFileName, UnitVersion.Revision, UnitVersion.Date]));
      end;
    end;
  finally
    MemoUnitVersioning.Lines.EndUpdate;
  end;
end;

{$IFDEF UNITVERSIONING}
initialization
  RegisterUnitVersion(HInstance, UnitVersioning);

finalization
  UnregisterUnitVersion(HInstance);
{$ENDIF UNITVERSIONING}

end.
