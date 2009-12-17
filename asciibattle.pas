program ASCIIBattle;

uses BattleField, Config, Physics, PhysicsTypes, ListOfRocket, crt;

procedure print(var f: BField);
var
	i, j: integer;
begin
	for j := 0 to f.height - 1 do
	begin
		for i := 0 to f.width - 1 do
			case f.arr[i, j].hp of
			0:
				write(' ');
			1..20:
				write('.');
			21..40:
				write('*');
			41..60:
				write('o');
			61..80:
				write('O');
			81..100:
				write('#');
			end;
		writeln;
	end;
end;

var
	f: BField;
	s, t: ansistring;
	pl: text;
	p: PhysicsController;
	r: Rocket;
	cr: pRocketNode;
begin
	new_bfield(f, 60, 40);
	assign(pl, 'field');
	reset(pl);
	readln(pl, s);
	s := s + ' ';
	while not eof(pl) do begin
		readln(pl, t);
		s := s + t;
	end;
	parse_bfield_string(f, s);

	new_pc(p, @f);
	new_rocket(r, 9, 37, 13, -25, 0, 9.81);
	push_front(p.rockets, r);
	new_rocket(r, 52, 36, -11, -11, 0, 9.81);
	push_front(p.rockets, r);
	new_rocket(r, 26, 31, -2, -30, 0, 9.81);
	push_front(p.rockets, r);
	clrscr;
	while true do
	begin
		gotoxy(1,1);
		print(f);
		cr := p.rockets.head;
		while cr <> nil do
		begin
			if ((cr^.v.position.x > 0) and (cr^.v.position.x < f.width) and
				(cr^.v.position.y > 0) and (cr^.v.position.y < f.height)) then begin
				gotoxy(trunc(cr^.v.position.x), trunc(cr^.v.position.y));
				write('R');
			end;
			cr := cr^.next;
		end;
		gotoxy(1,1);
		pc_step(p, 0.1);
		delay(100);
		if keypressed then
			break;
	end;
end.
