program asciibattle;
uses crt, CrtInterface, Game, Physics, BattleField, Geometry, SysUtils;

var
	iface: ABInterface;
	gc: GameController;
	pl: text;
	level, t: ansistring;

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
	gc.player1.cannon := iv(10, 15);
	new_abinterface(iface, @gc);
	iface.paneltr := '$4>$0Player 2$4<';
	iface.paneltl := ' Player 1';
	writeln('Initialized');
	while true do
	begin
		iface.panelbl := IntToStr(gc.pc^.rockets.size);
		iface.panelbr := IntToStr(iface.view.width) + ', ' + IntToStr(iface.view.height);
		gc_step(gc, 0.033);
		iface_step(iface);
		if keypressed then
			break;
		delay(33);
		gc_shoot(gc, PlayerOne, -0.78, 10);
	end;
end.
