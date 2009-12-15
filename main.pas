program ASCIIBattle;

uses Physics, Config;

procedure print(var f: BattleField);
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
	f: BattleField;
	s, t: ansistring;
begin
	battlefield_init(f, 10, 10);
	readln(s);
	s := s + ' ';
	while not eof do begin
		readln(t);
		s := s + t;
	end;

	parse_battlefield_string(f, s);
	print(f);
end.
