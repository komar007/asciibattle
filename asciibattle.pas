program ASCIIBattle;
{$ifdef fpc}
{$mode objfpc}
{$endif}
uses Geometry, BattleField, StaticConfig, Config, Physics, Types, Lists, crt;

procedure print(var f: BField);
var
	i, j: integer;
begin
	for j := 0 to f.height - 1 do
	begin
		for i := 0 to f.width - 1 do
			case trunc(f.arr[i, j].current_hp) of
			0:
				write(CH[0]);
			1..10:
				write(CH[1]);
			11..20:
				write(CH[2]);
			21..30:
				write(CH[3]);
			31..40:
				write(CH[4]);
			41..50:
				write(CH[5]);
			51..60:
				write(CH[6]);
			61..70:
				write(CH[7]);
			71..80:
				write(CH[8]);
			81..90:
				write(CH[9]);
			91..100:
				write(CH[10]);
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
	time, nextshot: double;
begin
	randomize;
	new_bfield(f, 171, 69);
	assign(pl, ParamStr(1));
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
	new_rocket(ro, v(9, 33), v(11, -10), v(0, 9.81), random(6) + 1, random(100));
	push_front(p.rockets, ro);
	new_rocket(ro, v(52, 30), v(-11, -21), v(0, 9.81), random(6) + 1, random(100));
	push_front(p.rockets, ro);
	new_rocket(ro, v(26, 29), v(2, -30), v(0, 9.81), random(6) + 1, random(100));
	push_front(p.rockets, ro);
	new_rocket(ro, v(53, 30), v(-14, -19), v(0, 9.81), random(6) + 1, random(100));
	push_front(p.rockets, ro);
	clrscr;
	textcolor(DarkGray);
	time := 0;
	nextshot := 1;
	while true do
	begin
		if abs(nextshot - time) < 0.1 then
		begin
			new_rocket(ro, v(random(f.width), random(f.height)), v(random(30) - 15, random(20) - 20), v(0, 9.81), random(6) + 1, random(60) + 70);
			if f.arr[iv(ro.position).x, iv(ro.position).y].current_hp = 0 then
			begin
				push_front(p.rockets, ro);
			end;
			nextshot := time + 0.3;
		end;
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
		textcolor(DarkGray);
		cr := p.rockets.head;
		while cr <> nil do
		begin
			if (cr^.v.position.y > 0) then begin
				gotoxy(1 + trunc(cr^.v.position.x), 1 + trunc(cr^.v.position.y));
				textcolor(LightRed);
				write('@');
				textcolor(DarkGray);
			end;
			cr := cr^.next;
		end;
		gotoxy(1,1);
		pc_step(p, 0.1);
		time := time + 0.1;
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
