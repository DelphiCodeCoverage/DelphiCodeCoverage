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
{ The Original Code is JclOtaExcDlgWizard.pas.                                                     }
{                                                                                                  }
{ The Initial Developer of the Original Code is Florent Ouchet                                     }
{         <outchy att users dott sourceforge dott net>                                             }
{ Portions created by Florent Ouchet are Copyright (C) of Florent Ouchet. All rights reserved.     }
{                                                                                                  }
{ Contributors:                                                                                    }
{                                                                                                  }
{**************************************************************************************************}
{                                                                                                  }
{ Last modified: $Date:: 2010-12-23 13:19:17 +0100 (jeu., 23 déc. 2010)                         $ }
{ Revision:      $Rev:: 3445                                                                     $ }
{ Author:        $Author:: outchy                                                                $ }
{                                                                                                  }
{**************************************************************************************************}

unit JclOtaExcDlgWizard;

interface

{$I jcl.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ActnList, ExtCtrls, StdCtrls,
  {$IFDEF UNITVERSIONING}
  JclUnitVersioning,
  {$ENDIF UNITVERSIONING}
  JclIDEUtils, JclPreProcessorExcDlgTemplates, JclOtaWizardForm;

type
  TJclOtaExcDlgForm = class(TJclWizardForm)
    procedure FormCreate(Sender: TObject);
  private
    FParams: TJclExcDlgParams;
  public
    constructor Create(AOwner: TComponent;
      AParams: TJclExcDlgParams); reintroduce;
    property Params: TJclExcDlgParams read FParams;
  end;

function ExcDlgWizard(var AParams: TJclExcDlgParams): Boolean;

{$IFDEF UNITVERSIONING}
const
  UnitVersioning: TUnitVersionInfo = (
    RCSfile: '$URL: https://jcl.svn.sourceforge.net:443/svnroot/jcl/tags/JCL-2.3-Build4197/jcl/experts/repository/ExceptionDialog/JclOtaExcDlgWizard.pas $';
    Revision: '$Revision: 3445 $';
    Date: '$Date: 2010-12-23 13:19:17 +0100 (jeu., 23 déc. 2010) $';
    LogPath: 'JCL\experts\repository\ExceptionDialog';
    Extra: '';
    Data: nil
    );
{$ENDIF UNITVERSIONING}

implementation

{$R *.dfm}

uses
  JclOtaResources, 
  JclOtaExcDlgFileFrame, JclOtaExcDlgFormFrame,
  JclOtaExcDlgSystemFrame, JclOtaExcDlgLogFrame,
  JclOtaExcDlgTraceFrame, JclOtaExcDlgThreadFrame,
  JclOtaExcDlgIgnoreFrame;

function ExcDlgWizard(var AParams: TJclExcDlgParams): Boolean;
var
  OwnsParams: Boolean;
  AForm: TJclOtaExcDlgForm;
begin
  Result := False;
  OwnsParams := False;

  if not Assigned(AParams) then
  begin
    OwnsParams := True;
    AParams := TJclExcDlgParams.Create;
  end;
  try
    AForm := TJclOtaExcDlgForm.Create(Application, AParams);
    try
      Result := AForm.Execute;
    finally
      AForm.Free;
    end;
  finally
    if OwnsParams and not Result then
      FreeAndNil(AParams);
  end;
end;

//=== { TJclOtaExcDlgForm.pas } ==============================================

constructor TJclOtaExcDlgForm.Create(AOwner: TComponent;
  AParams: TJclExcDlgParams);
begin
  FParams := AParams;
  inherited Create(AOwner);
end;

procedure TJclOtaExcDlgForm.FormCreate(Sender: TObject);
begin
  inherited FormCreate(Sender);
  Caption := LoadResString(@RsExceptionDialogConfigure);

  AddPage(TJclOtaExcDlgFilePage.Create(Self, Params));
  AddPage(TJclOtaExcDlgFormPage.Create(Self, Params));
  AddPage(TJclOtaExcDlgSystemPage.Create(Self, Params));
  AddPage(TJclOtaExcDlgLogPage.Create(Self, Params));
  AddPage(TJclOtaExcDlgIgnorePage.Create(Self, Params));
  AddPage(TJclOtaExcDlgTracePage.Create(Self, Params));
  AddPage(TJclOtaExcDlgThreadPage.Create(Self, Params));
end;

{$IFDEF UNITVERSIONING}
initialization
  RegisterUnitVersion(HInstance, UnitVersioning);

finalization
  UnregisterUnitVersion(HInstance);
{$ENDIF UNITVERSIONING}

end.
