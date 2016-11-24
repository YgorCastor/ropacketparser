library parser;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  Windows,
  Hook,
  Console,
  Main,
  socket in 'socket.pas',
  scriptDump in 'scriptDump.pas';

{$R *.res}

const
  packet_len_db = 'packet_len_db.txt';

var
  sendHook, recvHook: THook;
  splitBuffer: Pointer;
  splitTotalSize, splitCurPos: Cardinal;

var addrSend, addrRecv: Pointer;
function internal_send( const s: Integer; var Buf; len, flags: Integer ): Integer; stdcall;
asm
  jmp [addrSend]
end;

function internal_recv( const s: Integer; var Buf; len, flags: Integer ): Integer; stdcall;
asm
  jmp [addrRecv]
end;

function send_dest( const s: Integer; var Buf; len, flags: Integer ): Integer; stdcall;
begin
  Result := internal_send(s, Buf, len, flags);
end;

function recv_dest( const s: Integer; var Buf; len, flags: Integer ): Integer; stdcall;
var i: Cardinal;
    Buffer, Buffer_Copy: Pointer;
    command: Cardinal;
    BufferLen: Integer;
begin
  Result := internal_recv(s, Buf, len, flags);
  if Result <= 0 then
  begin
    Console.WriteLog('[Recv]', 'The client asked for packets, but there is nothing to parse.', CL_GREEN, []);
    Exit;
  end;
  //Console.WriteLog('[Recv]', 'Packet received (len: %d): %s', CL_GREEN, [Result, buf_to_text(@Buf, Result, true)]);
  i := 0;
  BufferLen := 0;
  GetMem(Buffer, len);
  Buffer_Copy := Buffer;
  CopyMemory(Buffer, @Buf, Result);
  if splitTotalSize > 0 then
  begin
    Console.WriteLog('[Recv]', 'Merging split buffer with received buffer and parsing.', CL_GREEN, []);
    CopyMemory(Pointer(Cardinal(splitBuffer)+splitCurPos), Buffer, splitTotalSize-splitCurPos);
    parse(splitBuffer, splitTotalSize, s, @internal_send);
    FreeMem(splitBuffer);
    splitBuffer := nil;
    i := splitTotalSize-splitCurPos;
    splitTotalSize := 0;
    splitCurPos := 0;
  end;
  while Integer(i) < Result do begin
    Buffer := Pointer(Cardinal(Buffer_Copy)+i);
    command := PWord(Buffer)^;
    if command > Length(packet_len_table)-1 then
    begin
      Console.WriteLog('[Warning]', 'Command 0x%x is higher than normal, maybe a wrong length for the last packet!', CL_YELLOW, [command]);
      Console.WriteLog('           ', '%s', CL_WHITE, [buf_to_text(Buffer_Copy, Result, True)]);
      break;
    end;
    if packet_len_table[command] > 0 then
      BufferLen := packet_len_table[command];
    if packet_len_table[command] = 0 then
    begin
      Console.WriteLog('[Warning]', 'Command 0x%x has no length in database, maybe a wrong length for the last packet!', CL_YELLOW, [command]);
      Console.WriteLog('           ', '%s', CL_WHITE, [buf_to_text(Buffer_Copy, Result, True)]);
      break;
    end;
    if packet_len_table[command] < 0 then
    begin
      BufferLen := PWord(Cardinal(Buffer)+2)^;
      //Console.WriteLog('[Recv]', 'Received a packet (0x%x) with undefined length. Using offset 0x2 (0x%x) as length.', CL_GREEN, [command, BufferLen]);
    end;
    if (Integer(i) + BufferLen) > Result then
    begin
      splitTotalSize := BufferLen;
      splitCurPos := Result - Integer(i);
      GetMem(splitBuffer, BufferLen);
      CopyMemory(splitBuffer, Buffer, splitCurPos);
      Console.WriteLog('[Recv]', 'Received a splitted packet. Parsing it later.', CL_GREEN, []);
      Break;
    end;
    parse(Buffer, BufferLen, s, @internal_send);
    {if not parse(Buffer, BufferLen) then
      log_packet_to_file(internalFormat('Unparsed packet at pos %d: %s', [i, buf_to_text(Buffer_Copy, Result)]));}
    i := i + Cardinal(BufferLen);
  end;
  FreeMem(Buffer_Copy);
end;

procedure Start();
begin
  Sleep(10000);
  if not Console.Init() then
  begin
    MessageBox(0, 'Failed to initialize Console.', 'Error!', 0);
    ExitProcess(0);
  end;
  Console.SetTitle('Packet Parser');
  populate_database(packet_len_db);
  Console.WriteLog('[Info]', 'Creating hook instance.', CL_CYAN, []);
  recvHook := THook.Create(GetProcAddress(LoadLibrary('ws2_32.dll'), 'recv'));
  recvHook.InstallHook(@recv_dest);
  sendHook := THook.Create(GetProcAddress(LoadLibrary('ws2_32.dll'), 'send'));
  sendHook.Create(@send_dest);
  Console.WriteLog('[Info]', 'Hook installed.', CL_CYAN, []);
  splitBuffer := nil;
  splitTotalSize := 0;
  splitCurPos := 0;
end;

var dummy: cardinal;
    startup: function ( const wVersionRequired: word; WSData: Pointer ): Integer; stdcall;
    dummy2: pointer;
begin
  getmem(dummy2, 512);
  startup := GetProcAddress(LoadLibrary('ws2_32.dll'), 'WSAStartup');
  startup($0202, dummy2);
  freemem(dummy2);
  addrSend := Pointer(Cardinal(GetProcAddress(LoadLibrary('ws2_32.dll'), 'send')) + 5);
  addrRecv := Pointer(Cardinal(GetProcAddress(LoadLibrary('ws2_32.dll'), 'recv')) + 5);
  CreateThread(nil, 0, @Start, nil, 0, dummy);
end.
