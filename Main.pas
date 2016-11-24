unit Main;

interface

uses SysUtils, StrUtils, Console, socket, scriptDump;

var
  packet_len_table: array [0..$8FF] of Integer;

var
  lastmap: String;

procedure populate_database(s: String);
function buf_to_text(P: Pointer; len: Integer; spaces: Boolean = False): String;
function parse(buf: Pointer; len, s: Integer; callback: pointer): Boolean;

implementation

procedure populate_database(s: String);
var F: TextFile; output, id, len: String; line, i: Integer;
begin
  i := 0;
  Console.WriteLog('[Info]', 'Reading database ''%s''...', CL_CYAN, [s]);
  AssignFile(F, s);
  if FileExists(s) then
  begin
    Reset(F);
    line := 1;
    while not EOF(F) do
    begin
      Readln(F, output);
      if (Length(output) > 2) then
      if (output[1] <> '/') and (output[2] <> '/') then
      begin
        if Pos(',',output) = 0 then
          Console.WriteLog('[Error]', 'Unknown structure for database on line %d! Skipping...', CL_RED, [line])
        else begin
          id := RightStr(output, Length(output) - 2); //skip 0x
          id := LeftStr(id, Pos(',', id) - 1);
          len := RightStr(output, Length(output) - Pos(',', output));
          i := i + 1;
          if StrToInt('$' + id) < Length(packet_len_table) then
          begin
            packet_len_table[StrToInt('$' + id)] := StrToIntDef(len, 2);
          end else
            Console.WriteLog('[Warning]', 'Packet in line %d is higher than 0x%x, please increase the limit!', CL_YELLOW, [line, Length(packet_len_table)]);
        end;
      end;
      line := line + 1;
    end;
    Console.WriteLog('[Info]', 'Done reading %d entries in database %s.', CL_CYAN, [i, s]);
  end else
    Console.WriteLog('[Error]', 'File not found ''%s''!', CL_RED, [s]);
  CloseFile(F);
end;

function buf_to_text(P: Pointer; len: Integer; spaces: Boolean = False): String;
var Buffer: PByteArray; i: Integer;
begin
  Result := '';
  Buffer := PByteArray(P);
  for i:=0 to len-1 do
  begin
    if spaces then
      Result := Result + IntToHex(Buffer[i],2) + ' '
    else
      Result := Result + IntToHex(Buffer[i],2);
  end;
  Result := Trim(Result);
end;

function RBUFS(b: Pointer; pos, len: uint32): String;
var i: uint32;
begin
  Result := '';
  for i := 0 to len do
  begin
    if RBUFB(b, pos+i) > 0 then
      Result := Result + Chr(RBUFB(b, pos+i))
    else
      break;
  end;
end;

function parse(buf: Pointer; len, s: Integer; callback: pointer): Boolean;
type tcallback = function ( const s: Integer; sbuf: pointer; len, flags: Integer ): Integer; stdcall;
var command: Word;
    sbuf, copy: pointer;
begin
  command := RBUFW(buf, 0);
  GetMem(sbuf, 1024);
  copy := sbuf;
  Result := True;
  case command of
    $0078: //non-npc insight
      begin
        Console.WriteLog('[Parse]', 'insight (npc-ns): %d (type: 0x%x) (class: %d) (pos: %d,%d,%d)', CL_MAGENTA, [RBUFL(buf, 3), RBUFB(buf, 2), RBUFW(buf, 15), RBUFPOS(buf, 47).x, RBUFPOS(buf, 47).y, RBUFPOS(buf, 47).d]);
        if RBUFB(buf, 2) = $6 then
        begin
          WBUFW(sbuf, 0)^ := $0094;
          WBUFL(sbuf, 2)^ := RBUFL(buf, 3);
          tcallback(callback)(s, sbuf, 6, 0);
          sbuf := WBUFP(sbuf, 11);
          scriptDumpGeneral(RBUFL(buf, 3), RBUFW(buf,15), RBUFPOS(buf, 47).x, RBUFPOS(buf, 47).y, RBUFPOS(buf, 47).d, lastmap);
        end;
      end;
    $007C:
      Console.WriteLog('[Parse]', 'insight (npc-s): %d (type: 0x%x) (class: %d)', CL_MAGENTA, [RBUFL(buf, 3), RBUFB(buf, 2), RBUFW(buf, 15)]);
    $007F:
      Console.WriteLog('[Parse]', 'ticksend: 0x%x', CL_MAGENTA, [RBUFL(buf, 2)]);
    $0091:
      begin
        Console.WriteLog('[Parse]', 'changemap: %s,%d,%d', CL_MAGENTA, [RBUFS(buf, 2, 16), RBUFW(buf, 18), RBUFW(buf, 20)]);
        lastmap := RBUFS(buf, 2, 16);
        lastmap := LeftStr(lastmap, Length(lastmap)-4); //cut ext
      end;
    $0092:
      begin
        Console.WriteLog('[Parse]', 'changemapserver: %s,%d,%d', CL_MAGENTA, [RBUFS(buf, 2, 16), RBUFW(buf, 18), RBUFW(buf, 20)]);
        lastmap := RBUFS(buf, 2, 16);
        lastmap := LeftStr(lastmap, Length(lastmap)-4); //cut ext
      end;
    $0094:
      Console.WriteLog('[Parse]', 'broadcast: %s', CL_MAGENTA, [RBUFS(buf, 4, len-4)]);
    $0095:
      begin
        Console.WriteLog('[Parse]', 'charnameack: %d: %s', CL_MAGENTA, [RBUFL(buf, 2), RBUFS(buf, 6, 24)]);
        if scriptIsDumped(RBUFL(buf, 2)) then
          scriptDumpName(RBUFL(buf, 2), RBUFS(buf, 6, 24));
      end;
    $00B1:
      Console.WriteLog('[Parse]', 'updatestatus (other): 0x%x %d', CL_MAGENTA, [command, RBUFW(buf, 2), RBUFL(buf, 4)]);
    $00B4:
      begin
        Console.WriteLog('[Parse]', 'scriptmes: %s', CL_MAGENTA, [RBUFS(buf, 8, len-9)]);
        if scriptIsDumped(RBUFL(buf, 4)) then
          scriptDumpDialog(RBUFL(buf, 4), RBUFS(buf, 8, len-9));
      end;
    $00B5:
      begin
        Console.WriteLog('[Parse]', 'scriptnext', CL_MAGENTA, []);
        if scriptIsDumped(RBUFL(buf, 2)) then
          scriptDumpWait(RBUFL(buf, 2));
      end;
    $00B6:
      begin
        Console.WriteLog('[Parse]', 'scriptclose', CL_MAGENTA, []);
        if scriptIsDumped(RBUFL(buf, 2)) then
          scriptDumpClose(RBUFL(buf, 2));
      end;
    $00B7:
      begin
        Console.WriteLog('[Parse]', 'scriptmenu: %s', CL_MAGENTA, [RBUFS(buf, 8, len-8)]);
        if scriptIsDumped(RBUFL(buf, 4)) then
          scriptDumpMenu(RBUFL(buf, 4), RBUFS(buf, 8, len-8));
      end;
    $0142:
      begin
        Console.WriteLog('[Parse]', 'scriptinput', CL_MAGENTA, []);
        if scriptIsDumped(RBUFL(buf, 2)) then
          scriptDumpInput(RBUFL(buf, 2));
      end;
    $01D4:
      begin
        Console.WriteLog('[Parse]', 'scriptinputstr', CL_MAGENTA, []);
        if scriptIsDumped(RBUFL(buf, 2)) then
          scriptDumpInputStr(RBUFL(buf, 2));
      end;
    $00BE:
      Console.WriteLog('[Parse]', 'updatestatus (needstatus): 0x%x %d', CL_MAGENTA, [RBUFW(buf, 2), RBUFB(buf, 4)]);
    $0121:
      Console.WriteLog('[Parse]', 'updatestatus (cart): %d/%d %d/%d', CL_MAGENTA, [RBUFW(buf, 2), RBUFW(buf, 4), RBUFL(buf, 6), RBUFL(buf, 10)]);
    $013A:
      Console.WriteLog('[Parse]', 'updatestatus (range): %d', CL_MAGENTA, [RBUFW(buf, 2)]);
    $0141:
      Console.WriteLog('[Parse]', 'updatestatus (status): 0x%x %d+%d', CL_MAGENTA, [RBUFL(buf, 2), RBUFL(buf, 6), RBUFL(buf, 10)]);
    $0195:
      Console.WriteLog('[Parse]', 'charnameack: 0x%x: %s (party: %s) (guild: %s) (pos: %s)', CL_MAGENTA, [RBUFL(buf, 2), RBUFS(buf, 6, 24), RBUFS(buf, 30, 24), RBUFS(buf, 54, 24), RBUFS(buf, 78, 24)]);
    $0289:
      Console.WriteLog('[Parse]', 'cashshop_ack: %d ROPs, %d Points (code: %d)', CL_MAGENTA, [RBUFW(buf, 2), RBUFW(buf, 4), RBUFW(buf, 6)]);
  else
    Result := False;
  end;
  FreeMem(copy);
end;

initialization
  lastmap := 'prontera';
end.
 