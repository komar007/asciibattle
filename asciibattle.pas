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

procedure read_fort(var field: BField; var conf: ConfigStruct; var pl: Player; num: integer);
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
	err := parse_bfield_string(field, conf.fort_pos[num], map, cannon, king, conf.fort_modifier, num, conf.initial_hp);
	if err.code <> OK then
	begin
		writeln('Error reading fort file: ', err.msg, ' (file: ', filename, ')');
		halt;
	end;
	pl.cannon := cannon + conf.fort_pos[num];
	pl.king := king + conf.fort_pos[num];
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
	p1, p2: Player;
begin	
	randomize;
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
	err := parse_bfield_string(bf, iv(0, 0), map, 1, 0, conf.initial_hp);
	if err.code <> OK then
	begin
		writeln('Error reading map file: ', err.msg, ' (file: ', filename, ')');
		halt;
	end;
	new_player(p1, conf.name[1], conf.color[1], conf.equipment, conf.max_force);
	new_player(p2, conf.name[2], conf.color[2], conf.equipment, conf.max_force);
	read_fort(bf, conf, p1, 1); 
	read_fort(bf, conf, p2, 2);
	new_gc(gc, @bf, p1, p2, conf.max_wind, conf.max_force);
	new_abinterface(iface, @gc);
	turn := 1;
	while True do
	begin
		if not iface.locked then
			gc_step(gc, 0.033);
		iface_step(iface);
		if iface.exitting then
			halt;
		if iface.shooting and not iface.locked then
		begin
			if gc_player_has_weapon(gc, gc.current_player, gc.player[gc.current_player].current_weapon) then
			begin
				gc_shoot(gc);
				iface_change_player(iface, (turn mod 2) + 1);
				inc(turn);
			end;
			iface.shooting := False;
		end;
		if gc.player[1].won or gc.player[2].won then
			iface.locked := True;
		delay(33);
	end;
end.
