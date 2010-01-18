program asciibattle;
uses CrtInterface, crt, Game, Physics, BattleField, Geometry, SysUtils;

var
	iface: ABInterface;
	gc: GameController;
	pl: text;
	level, t: ansistring;
	turn: integer;
begin
	assign(pl, ParamStr(1));
	reset(pl);
	readln(pl, level);
	level := level + ' ';
	while not eof(pl) do begin
		readln(pl, t);
		level := level + t;
	end;

	gc.player1.cannon := iv(5, 15);
	gc.player1.max_force := 30;
	gc.player2.cannon := iv(60, 12);
	gc.player2.max_force := 30;
	new_gc(gc, level);
	gc.current_player := @gc.player1;
	new_abinterface(iface, @gc);
	turn := 0;
	while true do
	begin
		gc_step(gc, 0.033);
		iface_step(iface);
		if iface.exitting then
			halt;
		if iface.shooting then
		begin
			if (turn mod 2) = 0 then
			begin
				gc_shoot(gc, PlayerOne, gc.player1.angle, gc.player1.force);
				gc.current_player := @gc.player2;
			end
			else
			begin
				gc_shoot(gc, PlayerTwo, gc.player2.angle, gc.player2.force);
				gc.current_player := @gc.player1;
			end;
			iface.shooting := False;
			inc(turn);
		end;
		delay(33);
	end;
end.
