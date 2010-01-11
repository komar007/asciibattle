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

	new_gc(gc, level);
	gc.player1.cannon := iv(5, 15);
	gc.player1.max_force := 30;
	gc.player2.cannon := iv(60, 12);
	gc.player2.max_force := 30;
	iface.shoot_max_force := 30;
	new_abinterface(iface, @gc);
	iface_set_sight(iface, iv(5,15), 3.14, 3);
	iface.paneltr := '$4>$0Player 2$4<';
	iface.paneltl := ' Player 1';
	writeln('Initialized');
	turn := 0;
	while true do
	begin
		write_panel(iface, Bottom, Left, IntToStr(gc.pc^.rockets.size));
		write_panel(iface, Bottom, Right, IntToStr(iface.view.width) + ', ' + IntToStr(iface.view.height));
		gc_step(gc, 0.033);
		iface_step(iface);
		if iface.exitting then
			halt;
		if iface.shooting then
		begin
			if (turn mod 2) = 0 then
			begin
				gc_shoot(gc, PlayerOne, iface_get_sight(iface), iface.shoot_force);
				gc.player1.angle := iface_get_sight(iface);
				gc.player1.force := iface.shoot_force;
				iface_set_sight(iface, gc.player2.cannon, gc.player2.angle, gc.player2.force);
				iface.shoot_max_force := gc.player2.max_force;
			end
			else
			begin
				gc_shoot(gc, PlayerTwo, iface_get_sight(iface), iface.shoot_force);
				gc.player2.angle := iface_get_sight(iface);
				gc.player2.force := iface.shoot_force;
				iface_set_sight(iface, gc.player1.cannon, gc.player1.angle, gc.player1.force);
				iface.shoot_max_force := gc.player1.max_force;
			end;
			iface.shooting := False;
			inc(turn);
		end;
		delay(33);
	end;
end.
