unit ModuleNameSpaceUnit;

interface

uses
  Classes,
  Generics.Collections;

type
  TModuleNameSpace = class
  strict private
    FName: string;
    FModules: TStringList;
    function GetCount: Integer;
  public
    property Name: String read FName;
    property Modules: TStringList read FModules;
    property Count: Integer read GetCount;

    constructor Create(const AName: string);
    destructor Destroy; override;

    procedure AddModule(const AModuleName: string);
    function HasModule(const AModuleName: string): Boolean;
  end;

  TModuleNameSpaceList = class
  strict private
    FNameSpaceList: TDictionary<string, TModuleNameSpace>;
    procedure ClearNameSpaceList;

    function GetModuleNameSpaceFromModuleName(const AModuleName: string): TModuleNameSpace;
  public
    property Items[const AModuleName: string]: TModuleNameSpace read GetModuleNameSpaceFromModuleName; default;

    constructor Create;
    destructor Destroy; override;

    procedure Add(const AModuleNameSpace: TModuleNameSpace);
  end;

  TUnitNameSpace = class
  strict private
    FModuleName: string;
    FUnits: TStringList;
    function GetCount: Integer;
  public
    property ModuleName: string read FModuleName;
    property Count: Integer read GetCount;

    constructor Create(const AModuleName: string);
    destructor Destroy; override;

    procedure AddUnit(const AUnitName: string);
    function HasUnit(const AUnitName: string): Boolean;
  end;

  TUnitNameSpaceList = class
  strict private
    FNameSpaceList: TDictionary<string, TUnitNameSpace>;
    procedure ClearNameSpaceList;
    function GetUnitNameSpace(const AName: string): TUnitNameSpace;
  public
    property Items[const AName: string]: TUnitNameSpace read GetUnitNameSpace; default;

    constructor Create;
    destructor Destroy; override;

    procedure Add(const AUnitNameSpace: TUnitNameSpace);
  end;

implementation

uses
  SysUtils;

{$region 'TModuleNameSpace'}
constructor TModuleNameSpace.Create(const AName: string);
begin
  inherited Create;

  FModules := TStringList.Create;
  FName := AName;
end;

destructor TModuleNameSpace.Destroy;
begin
  FModules.Free;
  inherited Destroy;
end;

function TModuleNameSpace.GetCount: Integer;
begin
  Result := Modules.Count;
end;

procedure TModuleNameSpace.AddModule(const AModuleName: string);
begin
  Modules.Add(AModuleName);
end;

function TModuleNameSpace.HasModule(const AModuleName: string): boolean;
begin
  Result := Modules.IndexOf(AModuleName) > -1;
end;
{$endregion 'TModuleNameSpace'}

{$region 'TModuleNameSpaceList'}
constructor TModuleNameSpaceList.Create;
begin
  inherited Create;

  FNameSpaceList := TDictionary<string, TModuleNameSpace>.Create;
end;

destructor TModuleNameSpaceList.Destroy;
begin
  ClearNameSpaceList;

  FNameSpaceList.Destroy;
  inherited Destroy;
end;

procedure TModuleNameSpaceList.ClearNameSpaceList;
var
  key: string;
begin
  for key in FNameSpaceList.Keys do
    FNameSpaceList[key].Free;
end;

function TModuleNameSpaceList.GetModuleNameSpaceFromModuleName(const AModuleName: STring): TModuleNameSpace;
var
  CurrentNameSpace: TModuleNameSpace;
begin
  Result := nil;
  for CurrentNameSpace in FNameSpaceList.Values do
  begin
    if CurrentNameSpace.HasModule(AModuleName) then
    begin
      Result := CurrentNameSpace;
      break;
    end;
  end;
end;

procedure TModuleNameSpaceList.Add(const AModuleNameSpace: TModuleNameSpace);
begin
  FNameSpaceList.Add(AModuleNameSpace.Name, AModuleNameSpace);
end;
{$endregion 'TModuleNameSpaceList'}

{$region 'TUnitNameSpace'}
constructor TUnitNameSpace.Create(const AModuleName: string);
begin
  inherited Create;

  FModuleName := AModuleName;
  FUnits := TStringList.Create;
end;

destructor TUnitNameSpace.Destroy;
begin
  FUnits.Free;
  inherited Destroy;
end;

procedure TUnitNameSpace.AddUnit(const AUnitName: string);
begin
  FUnits.Add(AUnitName);
end;

function TUnitNameSpace.GetCount: Integer;
begin
  Result := FUnits.Count;
end;

function TUnitNameSpace.HasUnit(const AUnitName: string): Boolean;
begin
  Result := FUnits.IndexOf(AUnitName) > -1;
end;
{$endregion 'TUnitNameSpace'}

{$region 'TUnitNameSpaceList'}
constructor TUnitNameSpaceList.Create;
begin
  inherited Create;
  FNameSpaceList := TDictionary<string, TUnitNameSpace>.Create;
end;

destructor TUnitNameSpaceList.Destroy;
begin
  ClearNameSpaceList;
  FNameSpaceList.Free;

  inherited Destroy;
end;

procedure TUnitNameSpaceList.ClearNameSpaceList;
var
  key: string;
begin
  for key in FNameSpaceList.Keys do
    FNameSpaceList[key].Free;
end;

procedure TUnitNameSpaceList.Add(const AUnitNameSpace: TUnitNameSpace);
begin
  FNameSpaceList.Add(AnsiUpperCase(AUnitNameSpace.ModuleName), AUnitNameSpace);
end;

function TUnitNameSpaceList.GetUnitNameSpace(const AName: string): TUnitNameSpace;
var
  key: string;
begin
  Result := nil;

  key := UpperCase(AName);
  if FNameSpaceList.ContainsKey(key) then
    Result := FNameSpaceList.Items[key];
end;
{$endregion 'TUnitNameSpaceList'}

end.
