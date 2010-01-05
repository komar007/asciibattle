unit Game;

interface
uses Physics, Geometry, Types, Lists;

type
	WhichPlayer = (PlayerOne, PlayerTwo);

	Player = record
		base: IntVector;
		cannon: IntVector;
	end;

	GameController = record
		pc: pPhysicsController;
		player1, player2: Player;
	end;

	pGameController = ^GameController;

procedure new_gc(var g: GameController; var levelstring: ansistring);
procedure gc_shoot(var g: GameController; pl: WhichPlayer; angle, speed: double);
procedure gc_step(var g: GameController; delta: double);


implementation
uses BattleField, Config;


procedure new_gc(var g: GameController; var levelstring: ansistring);
var
	bf: pBField;
	pc: pPhysicsController;
	field_w, field_h: integer;
begin
	parse_bfield_dimensions(levelstring, field_w, field_h);
	new(bf);
	new_bfield(bf^, field_w, field_h);
	parse_bfield_string(bf^, levelstring);
	new(pc);
	new_pc(pc^, bf);
	g.pc := pc;
end;

procedure gc_shoot(var g: GameController; pl: WhichPlayer; angle, speed: double);
var
	r: Rocket;
	whereshoot: IntVector;
begin
	if pl = PlayerOne then
		whereshoot := g.player1.cannon
	else
		whereshoot := g.player2.cannon;
	whereshoot := whereshoot - iv(0, -1);

	new_rocket(r,
		fc(whereshoot),                             { launch position (1 above cannon) }
		v(speed * cos(angle), speed * sin(angle)),  { initial velocity }
		v(0, 9.81),                                 { gravity }
		2,                                          { explosion radius }
		90                                          { explosion force }
	);
	pc_add_rocket(g.pc^, r);
end;

procedure gc_step(var g: GameController; delta: double);
begin
	pc_step(g.pc^, delta);
end;

begin
end.
