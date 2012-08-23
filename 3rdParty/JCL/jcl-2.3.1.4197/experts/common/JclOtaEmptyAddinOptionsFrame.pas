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
{ The Original Code is JclOtaEmptyAddinOptionsFrame.pas.                                           }
{                                                                                                  }
{ The Initial Developer of the Original Code is Uwe Schuster.                                      }
{ Portions created by Uwe Schuster are Copyright (C) 2010 Uwe Schuster. All rights reserved.       }
{                                                                                                  }
{ Contributor(s):                                                                                  }
{   Uwe Schuster (uschuster)                                                                       }
{                                                                                                  }
{**************************************************************************************************}
{                                                                                                  }
{ Last modified: $Date:: 2010-09-01 21:52:52 +0200 (mer., 01 sept. 2010)                         $ }
{ Revision:      $Rev:: 3322                                                                     $ }
{ Author:        $Author:: outchy                                                                $ }
{                                                                                                  }
{**************************************************************************************************}

unit JclOtaEmptyAddinOptionsFrame;

{$I jcl.inc}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls
  {$IFDEF UNITVERSIONING}
  , JclUnitVersioning
  {$ENDIF UNITVERSIONING}
  ;

type
  TJclOtaEmptyAddinOptionsFrm = class(TFrame)
    lbTitle: TLabel;
    Label1: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

{$IFDEF UNITVERSIONING}
const
  UnitVersioning: TUnitVersionInfo = (
    RCSfile: '$URL: https://jcl.svn.sourceforge.net:443/svnroot/jcl/tags/JCL-2.3-Build4197/jcl/experts/common/JclOtaEmptyAddinOptionsFrame.pas $';
    Revision: '$Revision: 3322 $';
    Date: '$Date: 2010-09-01 21:52:52 +0200 (mer., 01 sept. 2010) $';
    LogPath: 'JCL\experts\common';
    Extra: '';
    Data: nil
    );
{$ENDIF UNITVERSIONING}

implementation

{$R *.dfm}

end.
