unit Physics;

interface
uses Geometry, BattleField, Types, Lists, StaticConfig;

type
	PhysicsController = record
		field: pBField;
		rockets: RocketList;
		animlist: IntVectorList;
		time: double;
	end;

type
	asdasd = record
		a: integer;
	end;

procedure new_pc(var p: PhysicsController; bf: pBField);
procedure pc_step(var p: PhysicsController; delta: double);


implementation
uses math;


procedure new_pc(var p: PhysicsController; bf: pBField);
begin
	p.time := 0.0;
	new_list(p.rockets);
	p.field := bf;
end;

function pc_rocket_in_field(var p: PhysicsController; var r: Rocket) : boolean;
var
	pos: IntVector;
begin
	pos := rocket_integerpos(r);
	pc_rocket_in_field :=
		(pos.x >= 0) and (pos.x < p.field^.width) and
		(pos.y < p.field^.height);
end;

procedure explode(var p: PhysicsController; var r: Rocket);
var
	sx, ex, sy, ey: integer;
	i, j: integer;
	d, delta_hp: double;
begin
	sx := max(0,                   trunc(r.position.x - r.exp_radius));
	ex := min(p.field^.width - 1,  trunc(r.position.x + r.exp_radius));
	sy := max(0,                   trunc(r.position.y - r.exp_radius));
	ey := min(p.field^.height - 1, trunc(r.position.y + r.exp_radius));
	for j := sy to ey do
	begin
		for i := sx to ex do
		begin
			d := dist(r.position, fc(i, j));
			{ if a field is within explosion range }
			if d <= r.exp_radius then
			begin
				{ if a field is not being animated }
				if p.field^.arr[i, j].hp = p.field^.arr[i, j].current_hp then
					// push to the animation list
				delta_hp := r.exp_force / d;
				p.field^.arr[i, j].hp_speed := p.field^.arr[i, j].hp_speed + INITIAL_HP_SPEED / d;
				p.field^.arr[i, j].hp := max(0, p.field^.arr[i, j].hp - delta_hp);
			end
		end;
	end;
end;

procedure pc_step(var p: PhysicsController; delta: double);
var
	cur, t: pRocketNode;
	collision: IntVector;
	i, j: integer; { temporary!!!}
begin
	cur := p.rockets.head;
	while cur <> nil do
	begin
		rocket_step(cur^.v, delta);
		t := cur;
		cur := cur^.next;
		{ Find the first collision on a segment-approximated partial path from
		oldpos to position }
		collision := first_collision(p.field^, r(t^.v.oldpos, t^.v.position));
		if collision <> NOWHERE then
		begin
			t^.v.position := v(collision);
			explode(p, t^.v);
			remove(p.rockets, t)
		end
		else
		if not pc_rocket_in_field(p, t^.v) then
			remove(p.rockets, t);
	end;

	{temporary!!!}
	for j := 0 to p.field^.height - 1 do
		for i := 0 to p.field^.width - 1 do
			if p.field^.arr[i, j].current_hp > p.field^.arr[i, j].hp then
			begin
				p.field^.arr[i, j].current_hp := max(p.field^.arr[i, j].hp, p.field^.arr[i, j].current_hp - p.field^.arr[i, j].hp_speed * delta);
			end;

	p.time := p.time + delta;
end;

begin
end.
