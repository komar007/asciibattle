unit Physics;

interface
uses BattleField, PhysicsTypes, ListOfRocket;

type
	PhysicsController = record
		field: pBField;
		rockets: RocketList;
		time: real;
	end;

procedure new_pc(var p: PhysicsController; bf: pBField);
procedure pc_step(var p: PhysicsController; delta: real);


implementation


procedure new_pc(var p: PhysicsController; bf: pBField);
begin
	p.time := 0.0;
	new_list(p.rockets);
	p.field := bf;
end;

procedure pc_step(var p: PhysicsController; delta: real);
var
	cur: pRocketNode; 
begin
	cur := p.rockets.head;
	while cur <> nil do
	begin
		rocket_step(cur^.v, delta);
		cur := cur^.next;
	end;

	p.time := p.time + delta;
end;

begin
end.
