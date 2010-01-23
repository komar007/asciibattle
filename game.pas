unit Game;

interface
uses Physics, Geometry, BattleField, Types, Lists;

type
	WhichPlayer = (PlayerOne, PlayerTwo);

	Side = (FortLeft, FortRight);

	Player = record
		king: IntVector;
		cannon: IntVector;
		name: ansistring;
		{ Used to remember settings in 2 player turn-based mode }
		max_force: double;
		angle, force: double;
		color: shortint;
	end;
	pPlayer = ^Player;

	GameController = record
		pc: pPhysicsController;
		player: array[1..2] of Player;
		current_player: pPlayer;
		max_wind: double;
		wind_dir: integer;
	end;
	pGameController = ^GameController;

procedure new_player(var p: Player; name: ansistring; k, c: IntVector; max_force: double);
procedure new_gc(var g: GameController; bf: pBField; mw: double);
procedure gc_shoot(var g: GameController);
procedure gc_change_player(var g: GameController; p: integer);
procedure gc_step(var g: GameController; delta: double);
function gc_player_side(var g: GameController; var p: Player) : Side;
function gc_player_life(var g: GameController; p: integer) : integer;


implementation
uses Config, StaticConfig;


procedure new_player(var p: Player; name: ansistring; k, c: IntVector; max_force: double);
begin
	p.name := name;
	p.king := k;
	p.cannon := c;
	p.max_force := max_force;
end;

procedure new_gc(var g: GameController; bf: pBField; mw: double);
var
	pc: pPhysicsController;
begin
	new(pc);
	new_pc(pc^, bf);
	g.pc := pc;
	g.wind_dir := random(2) * 2 - 1;
	g.max_wind := mw;
end;

procedure gc_shoot(var g: GameController);
var
	r: Rocket;
	whereshoot: IntVector;
	force, angle: double;
begin
	whereshoot := g.current_player^.cannon - iv(0, 1);
	force := g.current_player^.force;
	angle := g.current_player^.angle;

	new_rocket(r,
		fc(whereshoot),                         { launch position (1 above cannon) }
		force * v(cos(angle), sin(angle)),  	{ initial velocity }
		v(0, 9.81),                             { gravity }
		1.5,                                    { explosion radius }
		30                                      { explosion force }
	);
	pc_add_rocket(g.pc^, r);
end;

procedure gc_change_player(var g: GameController; p: integer);
begin
	g.current_player := @g.player[p];
end;

procedure gc_step(var g: GameController; delta: double);
begin
	if random(50) = 0 then
		g.wind_dir := -g.wind_dir;
	g.pc^.wind := g.pc^.wind + g.wind_dir * WIND_FLUCT;
	if abs(g.pc^.wind) > g.max_wind then
	begin
		g.pc^.wind := g.max_wind * (g.pc^.wind / abs(g.pc^.wind));
		g.wind_dir := -g.wind_dir;
	end;
	pc_step(g.pc^, delta);
end;

{ Returns on which side of the field the player is }
function gc_player_side(var g: GameController; var p: Player) : Side;
begin
	if p.king.x < g.pc^.field^.width / 2 then
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

begin
end.
