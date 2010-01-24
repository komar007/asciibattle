unit Physics;

interface
uses Geometry, BattleField, Types, Lists;

type
	PhysicsController = record
		field: pBField;
		rockets: RocketList;
		{ The list of currently animated fields }
		animlist: IntVectorList;
		time: double;
		wind: Vector;
	end;
	pPhysicsController = ^PhysicsController;

procedure new_pc(var p: PhysicsController; bf: pBField);
procedure pc_step(var p: PhysicsController; delta: double);
procedure pc_add_rocket(var p: PhysicsController; r: Rocket);
function field_animated(var p: PhysicsController; v: IntVector) : boolean;


implementation
uses math, StaticConfig;


procedure new_pc(var p: PhysicsController; bf: pBField);
begin
	p.time := 0.0;
	p.wind := v(0, 0);
	p.field := bf;
	new_list(p.rockets);
	new_list(p.animlist);
end;

{ Checks whether rocket is still in battle field }
function pc_rocket_in_bfield(var p: PhysicsController; var r: Rocket) : boolean;
var
	pos: IntVector;
begin
	pos := iv(r.position);
	pc_rocket_in_bfield :=
		(pos.x >= 0) and (pos.x < p.field^.width) and
		(pos.y < p.field^.height);
end;

function field_animated(var p: PhysicsController; v: IntVector) : boolean;
begin
	{ If hp and current_hp are not equal, the field has a state of "during animation".
	  current_hp is always > or < than hp until the variables are equal and the animation stops. }
	field_animated := p.field^.arr[v.x, v.y].hp <> p.field^.arr[v.x, v.y].current_hp;
end;

{ Perform rocket explosion }
procedure explode(var p: PhysicsController; position: Vector; radius, force: double);
var
	{ start and end of explosion rectangle }
	s, e: IntVector;
	i, j: integer;
	d, delta_hp: double;
begin
	s := iv(position - v(radius, radius));
	e := iv(position + v(radius, radius));
	for j := max(0, s.y) to min(e.y, p.field^.height - 1) do
	begin
		for i := max(0, s.x) to min(e.x, p.field^.width - 1) do
		begin
			d := max(0.1, dist(position, fc(i, j)));
			{ if a field is within explosion range }
			if d <= radius then
			begin
				{ if a field is not being animated }
				if not field_animated(p, iv(i, j)) then
					push_front(p.animlist, iv(i, j));
				{ Update animation properties }
				p.field^.arr[i, j].hp_speed := max(MIN_HP_SPEED,
					p.field^.arr[i, j].hp_speed + INITIAL_HP_SPEED / (d*d));
				if force >= 0 then
					delta_hp := min(force, force / (d*d))
				else
					delta_hp := max(force, force / (d*d));
				p.field^.arr[i, j].hp := max(0, p.field^.arr[i, j].hp - delta_hp);
			end
		end;
	end;
end;

procedure rocket_step(var p: PhysicsController; var r: Rocket; delta: double);
begin
	r.oldpos := r.position;
	if not r.drilling then
		r.velocity := r.velocity + ((r.acceleration + p.wind) * delta);
	r.position := r.position + (r.velocity * delta);
	if r.drilling then
		r.current_drill_len := r.current_drill_len + len(r.position - r.oldpos);
end;

procedure rockets_step(var p: PhysicsController; delta: double);
var
	cur, t: pRocketNode;
	collision: IntVector;
begin
	cur := p.rockets.head;
	while cur <> nil do
	begin
		rocket_step(p, cur^.v, delta);
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
			if abs(t^.v.drill_len) < 0.1 then
			begin
				t^.v.position := fc(collision);
				explode(p, t^.v.position, t^.v.exp_radius, t^.v.exp_force);
				t^.v.removed := true; { Schedule the rocket to be removed in the next step }
				continue;
			end;
			if t^.v.drilling and (t^.v.current_drill_len >= t^.v.drill_len) then
			begin
				t^.v.position := fc(collision);
				explode(p, t^.v.position, t^.v.exp_radius, t^.v.exp_force);
				t^.v.removed := true; { Schedule the rocket to be removed in the next step }
			end
			else if not t^.v.drilling then
			begin
				t^.v.drilling := True;
				t^.v.velocity := t^.v.velocity * 0.2;
			end;
		end
		else if not pc_rocket_in_bfield(p, t^.v) then
			t^.v.removed := true { Schedule the rocket to be removed in the next step }
		else if t^.v.drilling then
		begin
			explode(p, t^.v.position, t^.v.exp_radius, t^.v.exp_force);
			t^.v.removed := true;
		end;
	end;
end;

{ Perform one step of fields animation }
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
			if field^.current_hp < field^.hp then
				field^.current_hp := min(field^.hp, field^.current_hp + field^.hp_speed * delta)
			else
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

procedure pc_add_rocket(var p: PhysicsController; r: Rocket);
begin
	push_front(p.rockets, r);
end;


begin
end.
