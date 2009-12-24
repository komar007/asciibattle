unit Physics;

interface
uses Geometry, BattleField, Types, ListOfRocket;

type
	PhysicsController = record
		field: pBField;
		rockets: RocketList;
		time: double;
	end;

procedure new_pc(var p: PhysicsController; bf: pBField);
function pc_rocket_in_field(var p: PhysicsController; var r: Rocket) : boolean;
procedure pc_step(var p: PhysicsController; delta: double);


implementation


procedure new_pc(var p: PhysicsController; bf: pBField);
begin
	p.time := 0.0;
	new_list(p.rockets);
	p.field := bf;
end;

function pc_rocket_in_field(var p: PhysicsController; var r: Rocket) : boolean;
var
	pos: Vector;
begin
	pos := rocket_integerpos(r);
	pc_rocket_in_field :=
		(pos.x >= 0) and (pos.x < p.field^.width) and
		(pos.y < p.field^.height);
end;

procedure pc_step(var p: PhysicsController; delta: double);
var
	cur, t: pRocketNode;
begin
	cur := p.rockets.head;
	while cur <> nil do
	begin
		rocket_step(cur^.v, delta);
		t := cur;
		cur := cur^.next;
		if not pc_rocket_in_field(p, t^.v) then
			remove(p.rockets, t);
		if first_collision(p.field^, r(t^.v.oldpos, t^.v.position)) <> NOWHERE then
			remove(p.rockets, t);
	end;

	p.time := p.time + delta;
end;

begin
end.
