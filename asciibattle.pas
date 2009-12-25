program ASCIIBattle;
{$ifdef fpc}
{$mode objfpc}
{$endif}
uses Geometry, BattleField, Config, Physics, Types, ListOfRocket, crt;

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
	ro: Rocket;
	cr: pRocketNode;
	a: IntVector;
	x1, x2, y1, y2: integer;
	c: char;
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

	x1 := 2;
	y1 := 4;
	x2 := 25;
	y2 := 35;

	new_pc(p, @f);
	new_rocket(ro, v(9, 33), v(11, -10), v(0, 9.81));
	push_front(p.rockets, ro);
	new_rocket(ro, v(52, 30), v(-11, -21), v(0, 9.81));
	push_front(p.rockets, ro);
	new_rocket(ro, v(26, 29), v(2, -30), v(0, 9.81));
	push_front(p.rockets, ro);
	new_rocket(ro, v(53, 30), v(-14, -19), v(0, 9.81));
	push_front(p.rockets, ro);
	clrscr;
	while true do
	begin
		a := first_collision(f, r(fc(x1,y1), fc(x2,y2)));
		gotoxy(1,1);
		print(f);
		gotoxy(a.x + 1, a.y + 1);
		textcolor(Red);
		write('X');
		gotoxy(x1+1, y1+1);
		textcolor(Blue);
		write('a');
		gotoxy(x2+1, y2+1);
		textcolor(Blue);
		write('b');
		textcolor(White);
		cr := p.rockets.head;
		while cr <> nil do
		begin
			if (cr^.v.position.y > 0) then begin
				gotoxy(1 + trunc(cr^.v.position.x), 1 + trunc(cr^.v.position.y));
				write('@');
			end;
			cr := cr^.next;
		end;
		gotoxy(1,1);
		pc_step(p, 0.1);
		delay(35);
		if keypressed then
		begin
			c := readkey;
			case c of
				#27: break;
				#0: begin
					c := readkey;
					case c of
						#72: dec(y1);
						#80: inc(y1);
						#75: dec(x1);
						#77: inc(x1);
					end;
				end;
			end;
		end;
	end;
end.
