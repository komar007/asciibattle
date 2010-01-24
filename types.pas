unit Types;

interface
uses Geometry;

type
	Rocket = record
		acceleration: Vector;
		velocity: Vector;
		position: Vector;
		oldpos: Vector;
		current_drill_len, drill_len: double;
		drilling: boolean;
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

procedure new_rocket(var r: Rocket; pos: Vector; vel: Vector; acc: Vector; rad: double; f: double; drill_len: double);


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

procedure new_rocket(var r: Rocket; pos: Vector; vel: Vector; acc: Vector; rad: double; f: double; drill_len: double);
begin
	r.oldpos := pos;
	r.position := pos;
	r.velocity := vel;
	r.acceleration := acc;
	r.removed := False;
	r.exp_radius := rad;
	r.exp_force := f;
	r.drilling := False;
	r.current_drill_len := 0;
	r.drill_len := drill_len;
end;

begin
end.
