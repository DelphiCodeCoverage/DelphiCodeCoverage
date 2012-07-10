unit ModuleNameSpaceUnit;

interface

uses Classes, Generics.Collections;

type
  TModuleNameSpace = class
  private
    fName: String;
    fModules: TStringList;
  public
    constructor Create(const name: String);
    destructor Destroy; overload;
    function GetName(): String;
    function GetModules(): TStringList;
    procedure AddModule(const modulename: String);
    function getCount(): Integer;
    function hasModule(const modulename: String): boolean;
  end;

  TModuleNameSpaceList = class
  private
    fNameSpaceList: TDictionary<String, TModuleNameSpace>;
  public
    constructor Create();
    destructor Destroy; override;
    procedure AddModuleNameSpace(const mns: TModuleNameSpace);
    function getModuleNamespace(const name: String): TModuleNameSpace;
    function getModuleNameSpaceFromModuleName(const modulename: STring)
      : TModuleNameSpace;
  end;

  TUnitNameSpace = class
  private
    fModuleName: String;
    fUnits: TStringList;
  public
    constructor Create(const modulename: String);
    destructor Destroy; override;
    function GetName(): String;
    function GetUnits(): TStringList;
    procedure AddUnit(const Unitname: String);
    function getCount(): Integer;
    function hasUnit(const Unitname: String): boolean;
  end;

  TUnitNameSpaceList = class
  private
    fNameSpaceList: TDictionary<String, TUnitNameSpace>;
  public
    constructor Create();
    destructor Destroy; override;
    procedure AddUnitNameSpace(const uns: TUnitNameSpace);
    function getUnitNamespace(const name: String): TUnitNameSpace;

  end;

implementation

uses sysutils;

constructor TUnitNameSpace.Create(const modulename: String);
begin
  fModuleName := modulename;
  fUnits := TStringList.Create;
end;

destructor TUnitNameSpace.Destroy;
begin
  fUnits.Free;
end;

function TUnitNameSpace.GetName(): String;
begin
  result := fModuleName;
end;

function TUnitNameSpace.GetUnits(): TStringList;
begin
  result := fUnits;
end;

procedure TUnitNameSpace.AddUnit(const Unitname: String);
begin
  fUnits.Add(Unitname);
end;

function TUnitNameSpace.getCount(): Integer;
begin
  result := fUnits.Count;
end;

function TUnitNameSpace.hasUnit(const Unitname: String): boolean;
begin
  result := fUnits.IndexOf(Unitname) > -1;
end;

constructor TUnitNameSpaceList.Create();
begin
  fNameSpaceList := TDictionary<String, TUnitNameSpace>.Create();
end;

destructor TUnitNameSpaceList.Destroy;
begin
  fNameSpaceList.Free;
end;

procedure TUnitNameSpaceList.AddUnitNameSpace(const uns: TUnitNameSpace);
begin
  fNameSpaceList.Add(AnsiUpperCase(uns.GetName), uns);
end;

function TUnitNameSpaceList.getUnitNamespace(const name: String)
  : TUnitNameSpace;
begin
  if fNameSpaceList.containsKey(UpperCase(name)) then
    result := fNameSpaceList.Items[UpperCase(name)]
  else
    result := nil;
end;

constructor TModuleNameSpaceList.Create;
begin
  fNameSpaceList := TDictionary<String, TModuleNameSpace>.Create;
end;

function TModuleNameSpaceList.getModuleNamespace(const name: string)
  : TModuleNameSpace;
begin
  if fNameSpaceList.containsKey(name) then
    result := fNameSpaceList.Items[name]
  else
    result := nil;
end;

function TModuleNameSpaceList.getModuleNameSpaceFromModuleName
  (const modulename: STring): TModuleNameSpace;
var
  iter: TEnumerator<TModuleNameSpace>;
begin
  result := nil;
  iter := fNameSpaceList.Values.GetEnumerator();
  while (iter.moveNext) do
  begin
    if iter.current.hasModule(modulename) then
    begin
      result := iter.current;
      break;
    end;

  end;
end;

destructor TModuleNameSpaceList.Destroy;
begin
  fNameSpaceList.Destroy;
end;

procedure TModuleNameSpaceList.AddModuleNameSpace(const mns: TModuleNameSpace);
begin
  fNameSpaceList.Add(mns.GetName, mns);
end;

constructor TModuleNameSpace.Create(const name: String);
begin
  fModules := TStringList.Create;
  fName := name;
end;

destructor TModuleNameSpace.Destroy;
begin
  fModules.Free;
end;

function TModuleNameSpace.GetName;
begin
  result := fName;
end;

function TModuleNameSpace.GetModules;
begin
  result := fModules;
end;

function TModuleNameSpace.getCount(): Integer;
begin
  result := fModules.Count;
end;

procedure TModuleNameSpace.AddModule(const modulename: string);
begin
  fModules.Add(modulename);
end;

function TModuleNameSpace.hasModule(const modulename: string): boolean;
begin
  result := fModules.IndexOf(modulename) > -1;
end;

end.
