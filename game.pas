unit Game;

interface
uses Physics, Geometry, BattleField, Types, Lists;

type
	WhichPlayer = (PlayerOne, PlayerTwo);

	Side = (FortLeft, FortRight);

	Player = record
		base: IntVector;
		cannon: IntVector;
		name: ansistring;
		{ Used to remember settings in 2 player turn-based mode }
		max_force: double;
		angle, force: double;
	end;
	pPlayer = ^Player;

	GameController = record
		pc: pPhysicsController;
		player1, player2: Player;
		current_player: pPlayer;
	end;
	pGameController = ^GameController;

procedure new_player(var p: Player; name: ansistring; b, c: IntVector; max_force: double);
procedure new_gc(var g: GameController; bf: pBField);
procedure gc_shoot(var g: GameController);
procedure gc_change_player(var g: GameController; var p: Player);
procedure gc_step(var g: GameController; delta: double);
function gc_player_side(var g: GameController; var p: Player) : Side;


implementation
uses Config;


procedure new_player(var p: Player; name: ansistring; b, c: IntVector; max_force: double);
begin
	p.name := name;
	p.base := b;
	p.cannon := c;
	p.max_force := max_force;
end;

procedure new_gc(var g: GameController; bf: pBField);
var
	pc: pPhysicsController;
begin
	new(pc);
	new_pc(pc^, bf);
	g.pc := pc;
end;

procedure gc_shoot(var g: GameController);
var
	r: Rocket;
	whereshoot: IntVector;
	force, angle: double;
begin
	whereshoot := g.current_player^.cannon - iv(0, -1);
	force := g.current_player^.force;
	angle := g.current_player^.angle;

	new_rocket(r,
		fc(whereshoot),                         { launch position (1 above cannon) }
		force * v(cos(angle), sin(angle)),  	{ initial velocity }
		v(0, 9.81),                             { gravity }
		2,                                      { explosion radius }
		50                                      { explosion force }
	);
	pc_add_rocket(g.pc^, r);
end;

procedure gc_change_player(var g: GameController; var p: Player);
begin
	g.current_player := @p;
end;

procedure gc_step(var g: GameController; delta: double);
begin
	pc_step(g.pc^, delta);
end;

{ Returns on which side of the field the player is }
function gc_player_side(var g: GameController; var p: Player) : Side;
begin
	if p.cannon.x < g.pc^.field^.width / 2 then
		gc_player_side := FortLeft
	else
		gc_player_side := FortRight;
end;

begin
end.
