unit Types;

interface
uses Geometry;

type
	Rocket = record
		acceleration: Vector;
		velocity: Vector;
		position: Vector;
		oldpos: Vector;
	end;

Operator = (a: Rocket; b: Rocket) eqrocket : boolean;

procedure new_rocket(var r: Rocket; pos: Vector; vel: Vector; acc: Vector);
procedure rocket_step(var r: Rocket; delta: double);
function rocket_integerpos(var r: Rocket) : IntVector;


implementation


{ Rocket operators }

Operator = (a: Rocket; b: Rocket) eqrocket : boolean;
begin
	eqrocket := a.position = b.position;
end;

{ Rocket functions }

procedure new_rocket(var r: Rocket; pos: Vector; vel: Vector; acc: Vector);
begin
	r.oldpos := pos;
	r.position := pos;
	r.velocity := vel;
	r.acceleration := acc;
end;

procedure rocket_step(var r: Rocket; delta: double);
begin
	r.oldpos := r.position;
	r.velocity := r.velocity + (r.acceleration * delta);
	r.position := r.position + (r.velocity * delta);
end;

function rocket_integerpos(var r: Rocket) : IntVector;
begin
	rocket_integerpos.x := trunc(r.position.x);
	rocket_integerpos.y := trunc(r.position.y);
end;

begin
end.
