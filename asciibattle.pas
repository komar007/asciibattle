program asciibattle;
uses
	Crt, CrtInterface,
	SysUtils,
	Game, Physics, BattleField, Geometry,
	Config, StaticConfig;

type
	ConfigType = (CGAME, CMAP, CFORT);

{ Returns the filename of a config file of given type and name }
function config_filename(t: ConfigType; name: ansistring) : ansistring;
var
	dir: ansistring;
begin
	case t of
		CGAME: dir := 'games';
		CMAP:  dir := 'maps';
		CFORT: dir := 'forts';
	end;
	config_filename := GetAppConfigDir(False) + '/' + dir + '/' + name;
	DoDirSeparators(config_filename);
end;

procedure create_stub_config(path: ansistring);
begin
	ForceDirectories(path);
	ForceDirectories(config_filename(CGAME, ''));
	ForceDirectories(config_filename(CFORT, ''));
	ForceDirectories(config_filename(CMAP, ''));
end;

procedure read_game_config(var conf: ConfigStruct; gamename: ansistring);
var
	filename: ansistring;
	confstring: ansistring;
	err: ErrorCode;
begin
	filename := config_filename(CGAME, gamename);
	err := read_file_to_string(filename, confstring);
	if err.code <> OK then
	begin
		writeln('Error: no such game (file: ', filename, ')'); 
		halt;
	end;
	err := parse_game_string(confstring, conf);
	if err.code <> OK then
	begin
		writeln('Error reading game file: ', err.msg, ' (file: ', filename, ')');
		halt;
	end;
end;

procedure read_fort(var gc: GameController; var conf: ConfigStruct; num: integer);
var
	filename: ansistring;
	err: ErrorCode;
	map: ansistring;
	cannon, king: IntVector;
begin
	filename := config_filename(CFORT, conf.fort_file[num]);
	err := read_file_to_string(filename, map);
	if err.code <> OK then
	begin
		writeln('Error: no such fort (file: ', filename, ')');
		halt;
	end;
	err := parse_bfield_string(gc.pc^.field^, conf.fort_pos[num], map, cannon, king);
	if err.code <> OK then
	begin
		writeln('Error reading fort file: ', err.msg, ' (file: ', filename, ')');
		halt;
	end;
	if num = 1 then
	begin
		gc.player1.cannon := cannon + conf.fort_pos[num];
		gc.player1.king := king + conf.fort_pos[num];
	end
	else
	begin
		gc.player2.cannon := cannon + conf.fort_pos[num];
		gc.player2.king := king + conf.fort_pos[num];
	end;
end;

var
	conf: ConfigStruct;
	confdir: ansistring;
	filename : ansistring;
	iface: ABInterface;
	err: ErrorCode;
	bf: BField;
	gc: GameController;
	map: ansistring;
	turn: integer;
	field_w, field_h: integer;
begin	
	if ParamCount = 0 then
	begin
		{ Temporary }
		writeln('Specify game name');
		halt;
	end;
	confdir := GetAppConfigDir(False);
	if not DirectoryExists(confdir) then
		create_stub_config(confdir);
	read_game_config(conf, ParamStr(1));
	filename := config_filename(CMAP, conf.bfield_file);
	err := read_file_to_string(filename, map);
	if err.code <> OK then
	begin
		writeln('Error: no such map (file: ', filename, ')');
		halt;
	end;
	err := parse_bfield_dimensions(map, field_w, field_h);
	if err.code <> OK then
	begin
		writeln('Error reading map file: ', err.msg, ' (file: ', filename, ')');
		halt;
	end;
	new_bfield(bf, field_w, field_h);
	err := parse_bfield_string(bf, iv(0, 0), map);
	if err.code <> OK then
	begin
		writeln('Error reading map file: ', err.msg, ' (file: ', filename, ')');
		halt;
	end;
	new_gc(gc, @bf);
	gc.player1.max_force := 30;
	gc.player2.max_force := 30;
	read_fort(gc, conf, 1); 
	read_fort(gc, conf, 2);

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
				iface_change_player(iface, gc.player2);
			end
			else
			begin
				gc_shoot(gc);
				iface_change_player(iface, gc.player1);
			end;
			iface.shooting := False;
			inc(turn);
		end;
		delay(33);
	end;
end.
