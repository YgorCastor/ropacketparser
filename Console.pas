unit Console;
{********************************************}
{* Made by Vianna - www.cronus-emulator.com *}
{********************************************}

interface

uses Windows, SysUtils;

const
  CL_BLACK        =  0;
  CL_BROWN        =  6;
  CL_LIGHTGRAY    =  7;
  CL_DARKGRAY     =  8;
  CL_BLUE    =  9;
  CL_GREEN   = 10;
  CL_CYAN    = 11;
  CL_RED     = 12;
  CL_MAGENTA = 13;
  CL_YELLOW        = 14;
  CL_WHITE        = 15;

function Init(): Boolean;
function Write(s: String): Boolean;
function WriteLine(s: String): Boolean;
function WriteLog(s, s2: String; c: Byte; const Args: array of const): Boolean;
function SetTitle(s: String): Boolean;
function SetColor(c: Byte): Boolean;
function ResetColor(): Boolean;

function internalFormat(const Format: string; const Args: array of const): string;

implementation

function Init(): Boolean;
begin
  FreeConsole();
  Result := AllocConsole();
  if Result then
    ResetColor();
end;

function Write(s: String): Boolean;
var written: Cardinal;
begin
  WriteConsole(GetStdHandle(STD_OUTPUT_HANDLE), PChar(s), Length(s), written, nil);
  Result := Integer(written) = Length(s);
end;

function WriteLine(s: String): Boolean;
begin
  Result := Write(s + #10);
end;

function WriteLog(s, s2: String; c: Byte; const Args: array of const): Boolean;
begin
  SetColor(c);
  Write(s);
  ResetColor();
  Result := WriteLine(' ' + Format(s2, Args));
end;

function internalFormat(const Format: string; const Args: array of const): string;
begin
  FmtStr(Result, Format, Args);
end;

function SetTitle(s: String): Boolean;
begin
  Result := SetConsoleTitle(PChar(s));
end;

function SetColor(c: Byte): Boolean;
begin
  Result := SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),(1 and $F0) or (c and $F));
end;

function ResetColor(): Boolean;
begin
  Result := SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),(1 and $F0) or (CL_WHITE and $F));
end;

end.
 