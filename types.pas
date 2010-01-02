unit Types;

interface
uses Geometry;

type
	Rocket = record
		acceleration: Vector;
		velocity: Vector;
		position: Vector;
		oldpos: Vector;
		removed: boolean;
		exp_radius: integer;
		exp_force: double;
	end;

Operator = (a: Rocket; b: Rocket) eqrocket : boolean;

procedure new_rocket(var r: Rocket; pos: Vector; vel: Vector; acc: Vector; rad: integer; f: double);
procedure rocket_step(var r: Rocket; delta: double);


implementation


{ Rocket operators }

Operator = (a: Rocket; b: Rocket) eqrocket : boolean;
begin
	eqrocket := a.position = b.position;
end;

{ Rocket functions }

procedure new_rocket(var r: Rocket; pos: Vector; vel: Vector; acc: Vector; rad: integer; f: double);
begin
	r.oldpos := pos;
	r.position := pos;
	r.velocity := vel;
	r.acceleration := acc;
	r.removed := false;
	r.exp_radius := rad;
	r.exp_force := f;
end;

procedure rocket_step(var r: Rocket; delta: double);
begin
	r.oldpos := r.position;
	r.velocity := r.velocity + (r.acceleration * delta);
	r.position := r.position + (r.velocity * delta);
end;

begin
end.
