unit Game;

interface
uses Physics, Geometry, BattleField, Types;

type
	Side = (FortLeft, FortRight);

	Player = record
		king: IntVector;
		cannon: IntVector;
		name: ansistring;
		max_force: double;
		angle, force: double;
		color: shortint;
		equipment: Equip;
		current_weapon: integer;
		won: boolean;
	end;
	pPlayer = ^Player;

	GameController = record
		pc: pPhysicsController;
		player: array[1..2] of Player;
		current_player: integer;
		max_wind: double;
		{ The starting max_force for both players }
		max_force: double;
		{ Tells whether the wind force is increasing or decreasing }
		wind_dir: integer;
		{ Flags for the main program }
	end;
	pGameController = ^GameController;

procedure new_player(var p: Player; name: ansistring; color: shortint; equipment: Equip; max_force: double);
procedure new_gc(var g: GameController; bf: pBField; var p1, p2: Player; max_wind, max_force: double);
procedure gc_shoot(var g: GameController);
procedure gc_change_player(var g: GameController; p: integer);
procedure gc_step(var g: GameController; delta: double);
function gc_player_side(var g: GameController; p: integer) : Side;
function gc_player_life(var g: GameController; p: integer) : integer;
function gc_player_has_weapon(g: GameController; p: integer; w: integer) : boolean;
function gc_field_is_king(var g: GameController; v: IntVector) : boolean;


implementation
uses Config, StaticConfig;


procedure set_player_initial_angle(var g: GameController; p: integer); forward;

procedure new_player(var p: Player; name: ansistring; color: shortint; equipment: Equip; max_force: double);
begin
	p.name := name;
	p.color := color;
	p.max_force := max_force;
	p.force := max_force / 2;
	p.equipment := equipment;
	p.current_weapon := 1;
	p.won := False;
end;

procedure new_gc(var g: GameController; bf: pBField; var p1, p2: Player; max_wind, max_force: double);
var
	pc: pPhysicsController;
begin
	new(pc);
	new_pc(pc^, bf);
	g.pc := pc;
	g.wind_dir := random(2) * 2 - 1;
	g.max_wind := max_wind;
	g.max_force := max_force;
	g.player[1] := p1;
	g.player[2] := p2;
	set_player_initial_angle(g, 1);
	set_player_initial_angle(g, 2);
	gc_change_player(g, 1);
end;

{ Chooses a comfortable initial angle for a player }
procedure set_player_initial_angle(var g: GameController; p: integer);
begin
	if gc_player_side(g, p) = FortLeft then
		g.player[p].angle := -pi/4
	else
		g.player[p].angle := -pi/4 * 3;
end;

{ Simulate a shot from current player's cannon }
procedure gc_shoot(var g: GameController);
var
	r: Rocket;
	whereshoot: IntVector;
	force, angle, bforce, bangle: double;
	current_player: pPlayer;
	current_weapon: pRocket;
	i: integer;
begin
	if gc_player_has_weapon(g, g.current_player, g.player[g.current_player].current_weapon) then
	begin
		current_player := @g.player[g.current_player];
		current_weapon := @current_player^.equipment[current_player^.current_weapon];
		whereshoot := current_player^.cannon - iv(0, 1);
		bforce := current_player^.force; force := bforce;
		bangle := current_player^.angle; angle := bangle;
		for i := 1 to current_weapon^.amount do
		begin
			new_rocket(r,
				fc(whereshoot),                         { launch position (1 above cannon) }
				force * v(cos(angle), sin(angle)),  	{ initial velocity }
				v(0, 9.81),                             { gravity }
				current_weapon^.exp_radius,             { explosion radius }
				current_weapon^.exp_force,              { explosion force }
				current_weapon^.drill_len               { drill length }
			);
			pc_add_rocket(g.pc^, r);
			angle := bangle + random(1000) / 4000.0 - 0.25;
			force := bforce + random(1000) / 250.0 - 2
		end;
		if current_weapon^.num <> -1 then
			dec(current_weapon^.num);
	end;
end;

procedure gc_change_player(var g: GameController; p: integer);
begin
	g.current_player := p;
end;

function check_loose(var g: GameController; var p: Player) : boolean;
begin
	check_loose := g.pc^.field^.arr[p.king.x, p.king.y].current_hp = 0;
end;

procedure wind_step(var g: GameController; delta: double);
begin
	if random(trunc(1/delta * WIND_CHANGE_TIME)) = 0 then
		g.wind_dir := -g.wind_dir;
	g.pc^.wind.x := g.pc^.wind.x + g.wind_dir * WIND_FLUCT*delta * (random(100)/100 + 0.5);
	if abs(g.pc^.wind.x) > g.max_wind then
	begin
		g.pc^.wind.x := g.max_wind * (g.pc^.wind.x / abs(g.pc^.wind.x));
		g.wind_dir := -g.wind_dir;
	end;
end;

procedure gc_step(var g: GameController; delta: double);
begin
	wind_step(g, delta);
	pc_step(g.pc^, delta);
	if check_loose(g, g.player[1]) then
		g.player[2].won := True;
	if check_loose(g, g.player[2]) then
		g.player[1].won := True;
end;

{ Returns on which side of the field the player is }
function gc_player_side(var g: GameController; p: integer) : Side;
var
	o: integer;
begin
	if p = 1 then o := 2 else o := 1;
	if g.player[p].king.x < g.player[o].king.x then
		gc_player_side := FortLeft
	else
		gc_player_side := FortRight;
end;

function gc_player_life(var g: GameController; p: integer) : integer;
var
	k: IntVector;
begin
	k := g.player[p].king;
	gc_player_life := trunc(g.pc^.field^.arr[k.x, k.y].hp);
end;

function gc_player_has_weapon(g: GameController; p: integer; w: integer) : boolean;
begin
	gc_player_has_weapon := (w <> 0) and (g.player[p].equipment[w].num > 0) or (g.player[p].equipment[w].num = -1);
end;

function gc_field_is_king(var g: GameController; v: IntVector) : boolean;
begin
	gc_field_is_king := (v = g.player[1].king) or (v = g.player[2].king);
end;


begin
end.
