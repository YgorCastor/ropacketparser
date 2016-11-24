unit socket;

interface

type
  uint8  = byte;      puint8  = ^uint8;
  uint16 = word;      puint16 = ^uint16;
  uint32 = cardinal;  puint32 = ^uint32;
  ro_pos = packed record
    x, y: uint16;
    d: uint8;
  end;

function WBUFP(b: Pointer; pos: uint32): pointer;
function WBUFB(b: Pointer; pos: uint32): puint8;
function WBUFW(b: Pointer; pos: uint32): puint16;
function WBUFL(b: Pointer; pos: uint32): puint32;
function WBUFQ(b: Pointer; pos: uint32): pint64;

function RBUFP(b: Pointer; pos: uint32): pointer;
function RBUFB(b: Pointer; pos: uint32): uint8;
function RBUFW(b: Pointer; pos: uint32): uint16;
function RBUFL(b: Pointer; pos: uint32): uint32;
function RBUFQ(b: Pointer; pos: uint32): int64;

function RBUFPOS(b: Pointer; pos: uint32): ro_pos;

implementation

function WBUFP(b: Pointer; pos: uint32): pointer;   begin Result := Pointer(uint32(b)+pos);  end;
function WBUFB(b: Pointer; pos: uint32): puint8;    begin Result :=  puint8(WBUFP(b, pos));  end;
function WBUFW(b: Pointer; pos: uint32): puint16;   begin Result := puint16(WBUFP(b, pos));  end;
function WBUFL(b: Pointer; pos: uint32): puint32;   begin Result := puint32(WBUFP(b, pos));  end;
function WBUFQ(b: Pointer; pos: uint32): pint64;    begin Result :=  pint64(WBUFP(b, pos));  end;

function RBUFP(b: Pointer; pos: uint32): pointer;   begin Result := Pointer(uint32(b)+pos);   end;
function RBUFB(b: Pointer; pos: uint32): uint8;     begin Result :=  puint8(RBUFP(b, pos))^;  end;
function RBUFW(b: Pointer; pos: uint32): uint16;    begin Result := puint16(RBUFP(b, pos))^;  end;
function RBUFL(b: Pointer; pos: uint32): uint32;    begin Result := puint32(RBUFP(b, pos))^;  end;
function RBUFQ(b: Pointer; pos: uint32): int64;     begin Result :=  pint64(RBUFP(b, pos))^;  end;

function RBUFPOS(b: Pointer; pos: uint32): ro_pos;
type bytearray = array [0..3] of Byte;
var p: pointer; carr: ^bytearray; c: integer;
begin
  p := pointer(uint32(b)+pos);
{  Result.x := (RBUFB(p,0) shl 2) or (RBUFB(p,1) shr 6);
  Result.y := ((RBUFB(p,1) and $3F) shl 4) or (RBUFB(p,1) shr 4);
  Result.d := RBUFB(p, 2) and $3F;}
  carr := @c;
  carr[2] := RBUFB(p, 0);
  carr[1] := RBUFB(p, 1);
  carr[0] := RBUFB(p, 2);
  Result.d := c and $F;
  Result.y := (c shr 4) and $3FF;
  Result.x := (c shr 14) and $3FF;
end;

end.
