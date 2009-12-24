unit Geometry;

interface
uses BattleField;

const
	COLLISION_RADIUS: double = 0.50;

type
	{ Represents a point or vector on a 2d plane }
	Vector = record
		x: double;
		y: double;
	end;

	{ Represents a pair of poins, a line segment or a rectangle on a 2d plane }
	Rect = record
		p1: Vector;
		p2: Vector;
	end;

{ Vector functions }
function v(x, y: double) : Vector;

{ Vector operators }
Operator - (a: Vector) v: Vector;
Operator = (a: Vector; b: Vector) v : boolean;
Operator + (a: Vector; b: Vector) v : Vector;
Operator - (a: Vector; b: Vector) v : Vector;
Operator * (a: Vector; b: double) v : Vector;
Operator * (a: double; b: Vector) v : Vector;

{ Rect functions }
function r(a, b: Vector) : Rect;
procedure rect_normalize(var r: Rect);

{ Collision detection functions }
function distance_point_line(p: Vector; l: Rect) : double;
function point_in_rect(p: Vector; r: Rect) : Boolean;
function collision_point_segment(p: Vector; s: Rect; radius: double) : Boolean;
function collision_field_segment(x, y: integer; s: Rect) : Boolean;


implementation
uses math, Types;


{ Creates a vector }
function v(x, y: double) : Vector;
begin
	v.x := x;
	v.y := y;
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

{ Counts the euclidean distance between a line and point on a 2d plane }
function distance_point_line(p: Vector; l: Rect) : double;
begin
	distance_point_line :=
		(l.p1.y - l.p2.y) * p.x +
		(l.p2.x - l.p1.x) * p.y +
		l.p1.x * l.p2.y - l.p2.x * l.p1.y;
	distance_point_line := abs(distance_point_line);
	distance_point_line := distance_point_line /
		sqrt(intpower(l.p1.y - l.p2.y, 2) + intpower(l.p2.x - l.p1.x, 2));
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
function collision_field_segment(x, y: integer; s: Rect) : Boolean;
begin
	collision_field_segment := collision_point_segment(v(x + 0.5, y + 0.5),
		s, COLLISION_RADIUS);
end;


begin
end.
