program ASCIIBattle;

uses BattleField, Config, Physics;

procedure print(var f: BField);
var
	i, j: integer;
begin
	for j := 0 to f.height - 1 do
	begin
		for i := 0 to f.width - 1 do
			write(f.arr[i, j].hp:4);
		writeln;
	end;
end;

var
	f: BField;
	s, t: ansistring;
begin
	bfield_init(f, 10, 10);
	readln(s);
	s := s + ' ';
	while not eof do begin
		readln(t);
		s := s + t;
	end;

	parse_bfield_string(f, s);
	print(f);
end.
