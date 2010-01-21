program asciibattle;
uses CrtInterface, crt, Game, Physics, BattleField, Geometry, Config, StaticConfig, SysUtils;

var
	iface: ABInterface;
	err: ErrorCode;
	bf: BField;
	gc: GameController;
	level: ansistring;
	turn: integer;
	field_w, field_h: integer;
begin
	err := read_file_to_string(ParamStr(1), level);
	if err.code <> OK then
	begin
		writeln(err.msg);
		halt;
	end;

	err := parse_bfield_dimensions(level, field_w, field_h);
	if err.code <> OK then
	begin
		writeln(err.msg);
		halt;
	end;

	new_bfield(bf, field_w, field_h);
	err := parse_bfield_string(bf, iv(0, 0), level);
	if err.code <> OK then
	begin
		writeln(err.msg);
		halt;
	end;

	gc.player1.cannon := iv(5, 15);
	gc.player1.max_force := 30;
	gc.player2.cannon := iv(60, 12);
	gc.player2.max_force := 30;
	new_gc(gc, @bf);
	gc_change_player(gc, gc.player1);
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
				gc_shoot(gc);
				gc_change_player(gc, gc.player2);
			end
			else
			begin
				gc_shoot(gc);
				gc_change_player(gc, gc.player1);
			end;
			iface.shooting := False;
			inc(turn);
		end;
		delay(33);
	end;
end.
