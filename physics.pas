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
	p.field := bf;
	new_list(p.rockets);
	new_list(p.animlist);
end;

function pc_rocket_in_bfield(var p: PhysicsController; var r: Rocket) : boolean;
var
	pos: IntVector;
begin
	pos := iv(r.position);
	pc_rocket_in_bfield :=
		(pos.x >= 0) and (pos.x < p.field^.width) and
		(pos.y < p.field^.height);
end;

function field_animated(var p: PhysicsController; x, y: integer) : boolean;
begin
	{ If hp and current_hp are not equal, the field has a state of "during animation".
	  current_hp is always > than hp until the variables are equal and the animation stops. }
	field_animated := p.field^.arr[x, y].hp <> p.field^.arr[x, y].current_hp;
end;

procedure explode(var p: PhysicsController; var r: Rocket);
var
	s, e: IntVector;
	i, j: integer;
	d, delta_hp: double;
begin
	s := iv(r.position - v(r.exp_radius, r.exp_radius));
	e := iv(r.position + v(r.exp_radius, r.exp_radius));
	for j := max(0, s.y) to min(e.y, p.field^.height - 1) do
	begin
		for i := max(0, s.x) to min(e.x, p.field^.width - 1) do
		begin
			d := dist(r.position, fc(i, j));
			d := max(d, 1);
			{ if a field is within explosion range }
			if d <= r.exp_radius then
			begin
				{ if a field is not being animated }
				if not field_animated(p, i, j) then
					push_front(p.animlist, iv(i, j));
				{ Update animation properties }
				p.field^.arr[i, j].hp_speed := max(MIN_HP_SPEED,
					p.field^.arr[i, j].hp_speed + INITIAL_HP_SPEED / (d*d));
				delta_hp := r.exp_force / (d*d);
				p.field^.arr[i, j].hp := max(0, p.field^.arr[i, j].hp - delta_hp);
			end
		end;
	end;
end;

procedure rocket_step(var r: Rocket; delta: double);
begin
	r.oldpos := r.position;
	r.velocity := r.velocity + (r.acceleration * delta);
	r.position := r.position + (r.velocity * delta);
end;

procedure rockets_step(var p: PhysicsController; delta: double);
var
	cur, t: pRocketNode;
	collision: IntVector;
begin
	cur := p.rockets.head;
	while cur <> nil do
	begin
		rocket_step(cur^.v, delta);
		t := cur;
		cur := cur^.next;
		{ If the rocket was scheduled for removal in the previous iteration... }
		if t^.v.removed then
		begin
			remove(p.rockets, t);
			continue;
		end;
		{ Find the first collision on a segment-approximated partial path from
		  oldpos to position }
		collision := first_collision(p.field^, r(t^.v.oldpos, t^.v.position));
		if collision <> NOWHERE then
		begin
			t^.v.position := fc(collision);
			explode(p, t^.v);
			t^.v.removed := true; { Schedule the rocket to be removed in the next step }
		end
		else if not pc_rocket_in_bfield(p, t^.v) then
			t^.v.removed := true; { Schedule the rocket to be removed in the next step }
	end;
end;

procedure fields_step(var p: PhysicsController; delta: double);
var
	cur, t: pIntVectorNode;
	field: pBFieldElement;
begin
	cur := p.animlist.head;
	while cur <> nil do
	begin
		{ save current field to work on }
		field := @(p.field^.arr[cur^.v.x, cur^.v.y]);
		t := cur;
		cur := cur^.next;
		{ Remove from animlist if animation stopped }
		if field^.hp = field^.current_hp then
			remove(p.animlist, t)
		else
		begin
			{ Animate field }
			field^.previous_hp := field^.current_hp;
			field^.current_hp := max(field^.hp, field^.current_hp - field^.hp_speed * delta);
		end;
	end;
end;

procedure pc_step(var p: PhysicsController; delta: double);
begin
	{ Animate rockets }
	rockets_step(p, delta);
	{ Animate fields }
	fields_step(p, delta);
	{ Update time }
	p.time := p.time + delta;
end;

begin
end.
