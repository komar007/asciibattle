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
		exp_radius: double;
		exp_force: double;
	end;

	ConfigPair = record
		key: ansistring;
		value: ansistring;
		line: integer;
	end;

Operator = (a: ConfigPair; b: ConfigPair) eqpair : boolean;
Operator = (a: Rocket; b: Rocket) eqrocket : boolean;

procedure new_rocket(var r: Rocket; pos: Vector; vel: Vector; acc: Vector; rad: double; f: double);


implementation

Operator = (a: ConfigPair; b: ConfigPair) eqpair : boolean;
begin
	eqpair := (a.key = b.key) and (a.value = b.value);
end;

{ Rocket operators }

Operator = (a: Rocket; b: Rocket) eqrocket : boolean;
begin
	eqrocket := a.position = b.position;
end;

{ Rocket functions }

procedure new_rocket(var r: Rocket; pos: Vector; vel: Vector; acc: Vector; rad: double; f: double);
begin
	r.oldpos := pos;
	r.position := pos;
	r.velocity := vel;
	r.acceleration := acc;
	r.removed := false;
	r.exp_radius := rad;
	r.exp_force := f;
end;

begin
end.
