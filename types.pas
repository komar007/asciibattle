unit PhysicsTypes;

interface

type
	Vector = record
		x: real;
		y: real;
	end;

	Rocket = record
		acceleration: Vector;
		velocity: Vector;
		position: Vector;
	end;

Operator = (a: Vector; b: Vector) eqvector : boolean;
Operator + (a: Vector; b: Vector) plusvector : Vector;
Operator * (a: Vector; b: real) scalevector : Vector;
Operator * (a: real; b: Vector) scalevector : Vector;

Operator = (a: Rocket; b: Rocket) eqrocket : boolean;

procedure new_rocket(var r: Rocket; x, y: real; vx, vy: real; ax, ay: real); 
procedure rocket_step(var r: Rocket; delta: real);
function rocket_integerpos(var r: Rocket) : Vector;


implementation


{ Vector operators }
Operator = (a: Vector; b: Vector) eqvector : boolean;
begin
	eqvector := (trunc(a.x) = trunc(b.x)) and (trunc(a.y) = trunc(b.y));
end;

Operator + (a: Vector; b: Vector) plusvector : Vector;
begin
	plusvector.x := a.x + b.x;
	plusvector.y := a.y + b.y;
end;

Operator * (a: Vector; b: real) scalevector : Vector;
begin
	scalevector.x := a.x * b;
	scalevector.y := a.y * b;
end;

Operator * (a: real; b: Vector) scalevector : Vector;
begin
	scalevector := b * a;
end;

{ Rocket operators }

Operator = (a: Rocket; b: Rocket) eqrocket : boolean;
begin
	eqrocket := a.position = b.position;
end;

{ Rocket functions }

procedure new_rocket(var r: Rocket; x, y: real; vx, vy: real; ax, ay: real);
begin
	r.position.x :=	x; r.position.y := y;
	r.velocity.x := vx; r.velocity.y := vy;
	r.acceleration.x := ax; r.acceleration.y := ay;
end;

procedure rocket_step(var r: Rocket; delta: real);
begin
	r.velocity := r.velocity + (r.acceleration * delta);
	r.position := r.position + (r.velocity * delta);
end;

function rocket_integerpos(var r: Rocket) : Vector;
begin
	rocket_integerpos.x := trunc(r.position.x);
	rocket_integerpos.y := trunc(r.position.y);
end;

begin
end.
