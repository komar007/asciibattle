program ASCIIBattle;
uses Geometry, BattleField, StaticConfig, Config, Physics, Types, Lists, crt;

procedure putchar(hp: integer);
begin
	case hp of
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
end;

procedure print(var p: PhysicsController);
var
	i, j: integer;
begin
	for j := 0 to p.field^.height - 1 do
	begin
		for i := 0 to p.field^.width - 1 do
			putchar(trunc(p.field^.arr[i, j].current_hp));
		writeln;
	end;
end;

procedure update(var p: PhysicsController);
var
	i, j: integer;
	cur: pIntVectorNode;
begin
	cur := p.animlist.head;
	while cur <> nil do
	begin
		i := cur^.v.x;
		j := cur^.v.y;
		gotoxy(i+1, j+1);
		putchar(trunc(p.field^.arr[i, j].current_hp));
		cur := cur^.next;
	end;
end;

var
	f: BField;
	s, t: ansistring;
	pl: text;
	p: PhysicsController;
	ro: Rocket;
	cr: pRocketNode;
	c: char;
	rv: IntVector;
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
	writeln('parsing');
	parse_bfield_string(f, s);

	new_pc(p, @f);
	clrscr;
	textcolor(DarkGray);
	time := 0;
	nextshot := 1;
	print(p);
	while true do
	begin
		pc_step(p, 0.03);
		time := time + 0.03;
		if abs(nextshot - time) < 0.1 then
		begin
			new_rocket(ro, v(random(f.width) * FIELD_WIDTH, random(f.height) * FIELD_HEIGHT), v(random(30) - 15, random(20) - 20), v(0, 9.81), random(2) + 1, random(60) + 70);
			if f.arr[iv(ro.position).x, iv(ro.position).y].current_hp = 0 then
			begin
				push_front(p.rockets, ro);
			end;
			nextshot := time + 0.25;
		end;
		gotoxy(1,1);
		update(p);
		cr := p.rockets.head;
		while cr <> nil do
		begin
			rv := iv(cr^.v.oldpos);
			if (rv.y >= 0) then begin
				gotoxy(1 + rv.x, 1 + rv.y);
				write(' ');
			end;
			rv := iv(cr^.v.position);
			if (rv.y >= 0) and not cr^.v.removed then begin
				textcolor(LightRed);
				gotoxy(1 + rv.x, 1 + rv.y);
				write('@');
				textcolor(DarkGray);
			end;
			cr := cr^.next;
		end;
		gotoxy(1,1);
		writeln('Rockets: ', p.rockets.size:4, ', animated fields: ', p.animlist.size:4);
		delay(33);
		if keypressed then
		begin
			c := readkey;
			case c of
				#27: break;
			end;
		end;
	end;
end.
