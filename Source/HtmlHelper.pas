unit HtmlHelper;

interface

function StartTag(const ATag: string; const ATagAttributes: string = ''): string;
function EndTag(const ATag: string): string;
function WrapTag(const AValue: string; const ATag: string; const ATagAttributes: string = ''): string;

function p(const AValue: string): string;
function bold(const AValue: string): string;
function heading(const AValue: string; const ALevel: Byte): string;
function td(const AValue: string): string;
function th(const AValue: string): string;
function tr(const AValue: string; const AAttributes: string = ''): string;
function table(const AValue: string; const AAttributes: string = ''): string;
function em(const AValue: string): string;
function pre(const AValue: string): string;
function link(
  const AValue: string;
  const AHref: string;
  const ATitle: string = ''): string;
function lineBreak: string;
function italics(const AValue: string): string;

implementation

uses
  SysUtils;

function StartTag(const ATag: string; const ATagAttributes: string = ''): string;
begin
  Result := '<' + LowerCase(ATag);
  if ATagAttributes <> '' then
    Result := Result + ' ' + ATagAttributes;
  Result := Trim(Result) + '>';
end;

function EndTag(const ATag: string): string;
begin
  Result := '</' + LowerCase(ATag) + '>';
end;

function WrapTag(const AValue: string; const ATag: string; const ATagAttributes: string = ''): string;
begin
  Result := StartTag(ATag, ATagAttributes) + AValue + EndTag(ATag);
end;

function p(const AValue: string): string;
begin
  Result := WrapTag(AValue, 'p');
end;

function bold(const AValue: string): string;
begin
  Result := WrapTag(AValue, 'strong');
end;

function heading(const AValue: string; const ALevel: Byte): string;
begin
  Result := WrapTag(AValue, 'h' + IntToStr(ALevel));
end;

function td(const AValue: string): string;
begin
  Result := WrapTag(AValue, 'td');
end;

function th(const AValue: string): string;
begin
  Result := WrapTag(AValue, 'th');
end;

function tr(const AValue: string; const AAttributes: string = ''): string;
begin
  Result := WrapTag(AValue, 'tr', AAttributes);
end;

function table(const AValue: string; const AAttributes: string = ''): string;
begin
  Result := WrapTag(AValue, 'table', AAttributes);
end;

function em(const AValue: string): string;
begin
  Result := WrapTag(AValue, 'em');
end;

function pre(const AValue: string): string;
begin
  Result := WrapTag(AValue, 'pre', 'style="display:inline;"');
end;

function link(
  const AValue: string;
  const AHref: string;
  const ATitle: string = ''): string;
var
  TagAttributes: string;
begin
  if Trim(AHref) <> '' then
    TagAttributes := 'href="' + Trim(AHref) + '"';

  if Trim(ATitle) <> '' then
    TagAttributes := TagAttributes + ' title="' + Trim(ATitle) + '"';

  Result := WrapTag(AValue, 'a', TagAttributes);
end;

function lineBreak: string;
begin
  Result := '<br />';
end;

function italics(const AValue: string): string;
begin
  Result := WrapTag(AValue, 'i');
end;


end.
