unit PhysicsTypes;

interface

type
	Vector = record
		x: integer;
		y: integer;
	end;

	Rocket = record
		acceleration: Vector;
		velocity: Vector;
		position: Vector;
	end;

Operator = (a: Rocket; b: Rocket) op : boolean;

implementation

Operator = (a: Rocket; b: Rocket) op : boolean;
begin
	op := true;
end;

begin
end.
