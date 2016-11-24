unit scriptDump;

interface

function scriptIsDumped(id: Integer): Boolean;

procedure scriptDumpGeneral(id, view_data, x, y, dir: Integer; mapName: String);
procedure scriptDumpDialog(id: Integer; dialog: String);
procedure scriptDumpWait(id: Integer);
procedure scriptDumpMenu(id: Integer; options: String);
procedure scriptDumpClose(id: Integer);
procedure scriptDumpName(id: Integer; name: String);
procedure scriptDumpInput(id: Integer);
procedure scriptDumpInputStr(id: Integer);

implementation

uses Console, Windows, SysUtils, Classes;

function scriptIsDumped(id: Integer): Boolean;
begin
  Result := FileExists(Format('script-%d.sc', [id]));
end;

procedure scriptDumpGeneral(id, view_data, x, y, dir: Integer; mapName: String);
var
  script: TextFile;
  fileName: String;
begin
  try
    try
      fileName := Format('script-%d.sc', [id]);
      AssignFile(script, fileName);
      if FileExists(fileName) then
        raise Exception.Create('This script is already dumped.');
      Rewrite(script);
      Writeln(script, Format('%s,%d,%d,%d'#9'script'#9'npcName'#9'%d,{', [mapName, x, y, dir, view_data]));
    except
      on E:Exception do
      begin
        Console.WriteLog('[Dump]', Format('Raised: %s', [E.Message]), CL_BROWN, []);
        Beep;
      end;
    end;
  finally
    try
      CloseFile(script);
    except end;
  end;
end;

procedure scriptDumpDialog(id: Integer; dialog: String);
var
  script: TextFile;
  fileName: String;
begin
  try
    try
      fileName := Format('script-%d.sc', [id]);
      AssignFile(script, fileName);
      if not FileExists(fileName) then
        raise Exception.Create('Failed to open dumped file.');
      Append(script);
      Writeln(script, Format(''#9'mes "%s";', [dialog]));
    except
      on E:Exception do
      begin
        Console.WriteLog('[Dump]', Format('Raised: %s', [E.Message]), CL_BROWN, []);
        Beep;
      end;
    end;
  finally
    try
      CloseFile(script);
    except end;
  end;
end;

procedure scriptDumpWait(id: Integer);
var
  script: TextFile;
  fileName: String;
begin
  try
    try
      fileName := Format('script-%d.sc', [id]);
      AssignFile(script, fileName);
      if not FileExists(fileName) then
        raise Exception.Create('Failed to open dumped file.');
      Append(script);
      Writeln(script, ''#9'next;');
    except
      on E:Exception do
      begin
        Console.WriteLog('[Dump]', Format('Raised: %s', [E.Message]), CL_BROWN, []);
        Beep;
      end;
    end;
  finally
    try
      CloseFile(script);
    except end;
  end;
end;

procedure scriptDumpMenu(id: Integer; options: String);
var
  script: TextFile;
  fileName: String;
begin
  try
    try
      fileName := Format('script-%d.sc', [id]);
      AssignFile(script, fileName);
      if not FileExists(fileName) then
        raise Exception.Create('Failed to open dumped file.');
      Append(script);
      Writeln(script,Format(''#9'select("%s");', [options]));
    except
      on E:Exception do
      begin
        Console.WriteLog('[Dump]', Format('Raised: %s', [E.Message]), CL_BROWN, []);
        Beep;
      end;
    end;
  finally
    try
      CloseFile(script);
    except end;
  end;
end;

procedure scriptDumpClose(id: Integer);
var
  script: TextFile;
  fileName, time, header: String;
begin
  try
    try
      fileName := Format('script-%d.sc', [id]);
      AssignFile(script, fileName);
      if not FileExists(fileName) then
        raise Exception.Create('Failed to open dumped file.');
      Reset(script);
      Readln(script, header);
      Append(script);
      Writeln(script, ''#9'close;');
      Writeln(script, '}');
      CloseFile(script);
      DateTimeToString(time, 'nnss', Now);
      CopyFile(PChar(fileName), PChar(Format('%s_%s.sc', [fileName, time])), True);
      AssignFile(script, fileName);
      Rewrite(script);
      Writeln(script, header);
    except
      on E:Exception do
      begin
        Console.WriteLog('[Dump]', Format('Raised: %s', [E.Message]), CL_BROWN, []);
        Beep;
      end;
    end;
  finally
    try
      CloseFile(script);
    except end;
  end;
end;

procedure scriptDumpName(id: Integer; name: String);
var
  script: TextFile;
  fileName: String;
  contents: array [0..1023] of String;
  i, lines: Integer;
begin
  try
    try
      fileName := Format('script-%d.sc', [id]);
      AssignFile(script, fileName);
      if not FileExists(fileName) then
        raise Exception.Create('Failed to open dumped file.');
      Reset(script);
      lines := 0;
      i := 0;
      while not EOF(script) do
      begin
        Readln(script, contents[i]);
        lines := lines + 1;
      end;
      Rewrite(script);
      Writeln(script, StringReplace(contents[0], 'npcName', name, [rfReplaceAll]));
      for i := 1 to lines do
        Writeln(script, contents[i]);
    except
      on E:Exception do
      begin
        Console.WriteLog('[Dump]', Format('Raised: %s', [E.Message]), CL_BROWN, []);
        Beep;
      end;
    end;
  finally
    try
      CloseFile(script);
    except end;
  end;
end;

procedure scriptDumpInput(id: Integer);
var
  script: TextFile;
  fileName: String;
begin
  try
    try
      fileName := Format('script-%d.sc', [id]);
      AssignFile(script, fileName);
      if not FileExists(fileName) then
        raise Exception.Create('Failed to open dumped file.');
      Append(script);
      Writeln(script, ''#9'input @inputnum;');
    except
      on E:Exception do
      begin
        Console.WriteLog('[Dump]', Format('Raised: %s', [E.Message]), CL_BROWN, []);
        Beep;
      end;
    end;
  finally
    try
      CloseFile(script);
    except end;
  end;
end;

procedure scriptDumpInputStr(id: Integer);
var
  script: TextFile;
  fileName: String;
begin
  try
    try
      fileName := Format('script-%d.sc', [id]);
      AssignFile(script, fileName);
      if not FileExists(fileName) then
        raise Exception.Create('Failed to open dumped file.');
      Append(script);
      Writeln(script, ''#9'input @inputstr$;');
    except
      on E:Exception do
      begin
        Console.WriteLog('[Dump]', Format('Raised: %s', [E.Message]), CL_BROWN, []);
        Beep;
      end;
    end;
  finally
    try
      CloseFile(script);
    except end;
  end;
end;

end.
