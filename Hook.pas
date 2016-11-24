unit Hook;
{********************************************}
{* Made by Vianna - www.cronus-emulator.com *}
{********************************************}

interface

uses Windows;

type
  THook = class
  private
    OriginalBytes, PatchedBytes: array [0..4] of Byte;
    FTarget: Pointer;
    FInstalled: Boolean;
  public
    constructor Create(lpTarget: Pointer);
    destructor Destroy(); override;
    function InstallHook(lpDestination: Pointer): Boolean;
    function UninstallHook(): Boolean;
    property Target: Pointer read FTarget;
    property Installed: Boolean read FInstalled;
  end;

implementation

var
  addrVirtualProtect: Pointer;

function InternalVirtualProtect(lpAddress: Pointer; dwSize, flNewProtect: DWORD; lpflOldProtect: Pointer): BOOL; stdcall;
asm
  jmp [addrVirtualProtect]
end;

{ THook }

constructor THook.Create(lpTarget: Pointer);
begin
  CopyMemory(@OriginalBytes, lpTarget, 5);
  FTarget := lpTarget;
  FInstalled := False;
end;

destructor THook.Destroy;
begin
  if FInstalled then
    UninstallHook();
  inherited;
end;

function THook.InstallHook(lpDestination: Pointer): Boolean;
var
  dwOldProtect: Cardinal;
begin
  Result := False;
  PatchedBytes[0] := $E9;
  PCardinal(@PatchedBytes[1])^ := Cardinal(lpDestination) - Cardinal(FTarget) - 5;
  if not FInstalled then
  begin
    if InternalVirtualProtect(FTarget, 5, PAGE_EXECUTE_READWRITE, @dwOldProtect) then
    begin
      CopyMemory(FTarget, @PatchedBytes, 5);
      if InternalVirtualProtect(FTarget, 5, dwOldProtect, nil) then
      begin
        Result := True;
        FInstalled := True;
      end;
    end;
  end;
end;

function THook.UninstallHook: Boolean;
var
  dwOldProtect: Cardinal;
begin
  Result := False;
  if FInstalled then
  begin
    if InternalVirtualProtect(FTarget, 5, PAGE_EXECUTE_READWRITE, @dwOldProtect) then
    begin
      CopyMemory(FTarget, @OriginalBytes, 5);
      if InternalVirtualProtect(FTarget, 5, dwOldProtect, nil) then
      begin
        Result := True;
        FInstalled := False;
      end;
    end;
  end;
end;

initialization
  addrVirtualProtect := Pointer(Cardinal(GetProcAddress(LoadLibrary('kernel32.dll'), 'VirtualProtect')) + 5);
end.
