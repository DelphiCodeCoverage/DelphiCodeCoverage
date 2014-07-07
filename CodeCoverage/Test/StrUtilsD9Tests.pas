unit StrUtilsD9Tests;

interface

uses
  Types,
  TestFramework,
  StrUtilsD9;

type
  TestSplitString = class(TTestCase)
  strict private
    FSplitted: TStringDynArray;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure EmptyStringShouldReturnSingleEmptyElement;
    procedure EmptyDelimiterShouldReturnSingleElement;
    procedure StringWithOneDelimiterShouldBeSplitIntoTwoElements;
    procedure StringWithTwoDelimitersOfSameTypeShouldBeSplitIntoThreeElements;
    procedure StringWithMultipleDelimitersOfDifferentTypesShouldBeSplit;
  end;

implementation

procedure TestSplitString.Setup;
begin
  SetLength(FSplitted, 0);
end;

procedure TestSplitString.TearDown;
begin
  SetLength(FSplitted, 0);
end;

procedure TestSplitString.EmptyStringShouldReturnSingleEmptyElement;
begin
  FSplitted := SplitString('', '');
  CheckEquals(0, Length(FSplitted), 'Element length should be 0');
end;

procedure TestSplitString.EmptyDelimiterShouldReturnSingleElement;
begin
  FSplitted := SplitString('Hello World', '');
  CheckEquals(1, Length(FSplitted), 'Element length should be 1');
  CheckEqualsString('Hello World', FSplitted[0], 'First entry should be ''Hello World''');
end;

procedure TestSplitString.StringWithOneDelimiterShouldBeSplitIntoTwoElements;
begin
  FSplitted := SplitString('Hello World', ' ');
  CheckEquals(2, Length(FSplitted), 'Element length should be 2');
  CheckEqualsString('Hello', FSplitted[0], 'First entry should be ''Hello''');
  CheckEqualsString('World', FSplitted[1], 'Second entry should be ''World''');
end;

procedure TestSplitString.StringWithTwoDelimitersOfSameTypeShouldBeSplitIntoThreeElements;
begin
  FSplitted := SplitString('Hello Huhu Ciao', ' ');
  CheckEquals(3, Length(FSplitted), 'Element length should be 3');
  CheckEqualsString('Hello', FSplitted[0], 'First entry should be ''Hello''');
  CheckEqualsString('Huhu', FSplitted[1], 'Second entry should be ''Huhu''');
  CheckEqualsString('Ciao', FSplitted[2], 'Third entry should be ''Ciao''');
end;

procedure TestSplitString.StringWithMultipleDelimitersOfDifferentTypesShouldBeSplit;
begin
  FSplitted := SplitString('Hello Huhu$Ciao|World-Universe', ' $|-');
  CheckEquals(5, Length(FSplitted), 'Element length should be 5');
  CheckEqualsString('Hello', FSplitted[0], 'First entry should be ''Hello''');
  CheckEqualsString('Huhu', FSplitted[1], 'Second entry should be ''Huhu''');
  CheckEqualsString('Ciao', FSplitted[2], 'Third entry should be ''Ciao''');
  CheckEqualsString('World', FSplitted[3], 'Fourth entry should be ''World''');
  CheckEqualsString('Universe', FSplitted[4], 'Fifth entry should be ''Universe''');
end;

initialization
  RegisterTest(TestSplitString.Suite);
end.
