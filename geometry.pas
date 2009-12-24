unit Geometry;

interface
uses BattleField;

const
	COLLISION_RADIUS: double = 0.50;
	INF: integer = 10000;

type
	{ Represents a point or vector on a 2d plane }
	Vector = record
		x: double;
		y: double;
	end;

	IntVector = record
		x: integer;
		y: integer;
	end;

	{ Represents a pair of poins, a line segment or a rectangle on a 2d plane }
	Rect = record
		p1: Vector;
		p2: Vector;
	end;

{ Vector functions }
function v(x, y: double) : Vector;
function v(vec: IntVector) : Vector;
function iv(x, y: integer) : IntVector;
function iv(vec: Vector) : IntVector;
function len(vec: Vector) : double;

{ Vector operators }
Operator - (a: Vector) v: Vector;
Operator = (a: Vector; b: Vector) v : boolean;
Operator + (a: Vector; b: Vector) v : Vector;
Operator - (a: Vector; b: Vector) v : Vector;
Operator * (a: Vector; b: double) v : Vector;
Operator * (a: double; b: Vector) v : Vector;
Operator + (a: IntVector; b: IntVector) v : IntVector;

{ Rect functions }
function r(a, b: Vector) : Rect;
procedure rect_normalize(var r: Rect);

{ Collision detection functions }
function dist(v1, v2: Vector) : double;
function distance_point_line(p: Vector; l: Rect) : double;
function point_in_rect(p: Vector; r: Rect) : Boolean;
function collision_point_segment(p: Vector; s: Rect; radius: double) : Boolean;
function collision_field_segment(vec: IntVector; s: Rect) : Boolean;
function first_collision(var f: BField; s: Rect) : IntVector;


implementation
uses math, Types;


{ Creates a vector }
function v(x, y: double) : Vector;
begin
	v.x := x;
	v.y := y;
end;

function v(vec: IntVector) : Vector;
begin
	v.x := vec.x;
	v.y := vec.y;
end;

function iv(x, y: integer) : IntVector;
begin
	iv.x := x;
	iv.y := y;
end;

function iv(vec: Vector) : IntVector;
begin
	iv.x := trunc(vec.x);
	iv.y := trunc(vec.y);
end;

function len(vec: Vector) : double;
begin
	len := sqrt(intpower(vec.x, 2) + intpower(vec.y, 2));
end;
{ Vector operators }

Operator - (a: Vector) v: Vector;
begin
	v := a * (-1);
end;

Operator = (a: Vector; b: Vector) v : boolean;
begin
	v := (trunc(a.x) = trunc(b.x)) and (trunc(a.y) = trunc(b.y));
end;

Operator + (a: Vector; b: Vector) v : Vector;
begin
	v.x := a.x + b.x;
	v.y := a.y + b.y;
end;

Operator - (a: Vector; b: Vector) v : Vector;
begin
	v := a + (-b);
end;

Operator * (a: Vector; b: double) v : Vector;
begin
	v.x := a.x * b;
	v.y := a.y * b;
end;

Operator * (a: double; b: Vector) v : Vector;
begin
	v := b * a;
end;

Operator + (a: IntVector; b: IntVector) v : IntVector;
begin
	v.x := a.x + b.x;
	v.y := a.y + b.y;
end;

{ Rect functions }

{ Creates a rect }
function r(a, b: Vector) : Rect;
begin
	r.p1 := a;
	r.p2 := b;
end;

procedure rect_normalize(var r: Rect);
var
	x1, y1, x2, y2: double;
begin
	x1 := min(r.p1.x, r.p2.x);
	y1 := min(r.p1.y, r.p2.y);
	x2 := max(r.p1.x, r.p2.x);
	y2 := max(r.p1.y, r.p2.y);
	r.p1 := v(x1, y1);
	r.p2 := v(x2, y2);
end;

{ Collision detection }

function dist(v1, v2: Vector) : double;
begin
	dist := len(v1 - v2);
end;

{ Counts the euclidean distance between a line and point on a 2d plane }
function distance_point_line(p: Vector; l: Rect) : double;
begin
	distance_point_line :=
		(l.p1.y - l.p2.y) * p.x +
		(l.p2.x - l.p1.x) * p.y +
		l.p1.x * l.p2.y - l.p2.x * l.p1.y;
	distance_point_line := abs(distance_point_line);
	distance_point_line := distance_point_line / dist(l.p1, l.p2);
end;

{ Checks if a point is inside of a rectangle }
function point_in_rect(p: Vector; r: Rect) : Boolean;
begin	
	rect_normalize(r);
	point_in_rect :=
		(r.p1.x < p.x) and (p.x < r.p2.x) and
		(r.p1.y < p.y) and (p.y < r.p2.y);
end;

{ Checks if a point is at most at distance radius from a line segment }
function collision_point_segment(p: Vector; s: Rect; radius: double) : Boolean;
var
	r: Rect;
begin
	{ Check if the point lays in a sensible rectangle delimiting the segment } 
	r := s;
	rect_normalize(r);
	r.p1 := r.p1 - v(radius, radius);
	r.p2 := r.p2 + v(radius, radius);
	if not point_in_rect(p, s) then
	begin
		collision_point_segment := false;
		exit;
	end;
	{ If the point is in the rectangle, it is sufficient to check the distance
	to the line }
	collision_point_segment := distance_point_line(p, s) < radius;
end;

{ Checks for intersection between a field and line segment }
function collision_field_segment(vec: IntVector; s: Rect) : Boolean;
begin
	collision_field_segment := collision_point_segment(v(vec) + v(0.5, 0.5),
		s, COLLISION_RADIUS);
end;

function first_collision(var f: BField; s: Rect) : IntVector;
var
	r: Rect;
	i, j: integer;
begin
	r := s;
	rect_normalize(r);
	first_collision := iv(INF, INF);
	for j := trunc(r.p1.y) to trunc(r.p2.y) do
		for i := trunc(r.p1.x) to trunc(r.p2.x) do
			if (dist(v(i + 0.5, j + 0.5), s.p1) < dist(v(first_collision) + v(0.5, 0.5), s.p1)) and
				collision_field_segment(iv(i, j), s) then
				first_collision := iv(i, j);	
end;


begin
end.
