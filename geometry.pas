unit Geometry;

interface

type
	Vector = record
		x: double;
		y: double;
	end;

	Rect = record
		p1: Vector;
		p2: Vector;
	end;

const
	COLLISION_RADIUS: double = 0.50;

function v(x, y: double) : Vector;

Operator - (a: Vector) vect: Vector;
Operator = (a: Vector; b: Vector) eqvector : boolean;
Operator + (a: Vector; b: Vector) plusvector : Vector;
Operator - (a: Vector; b: Vector) diff : Vector;
Operator * (a: Vector; b: double) scalevector : Vector;
Operator * (a: double; b: Vector) scalevector : Vector;

function r(a, b: Vector) : Rect;
procedure rect_normalize(var r: Rect);

function distance_point_line(p: Vector; l: Rect) : double;
function point_in_rect(p: Vector; r: Rect) : Boolean;
function collision_point_segment(p: Vector; var s: Rect; radius: double) : Boolean;
function collision_field_segment(x, y: integer; var s: Rect) : Boolean;


implementation
uses math, Types;


function v(x, y: double) : Vector;
begin
	v.x := x;
	v.y := y;
end;

{ Vector operators }

Operator - (a: Vector) vect: Vector;
begin
	vect.x := -a.x;
	vect.y := -a.y;
end;

Operator = (a: Vector; b: Vector) eqvector : boolean;
begin
	eqvector := (trunc(a.x) = trunc(b.x)) and (trunc(a.y) = trunc(b.y));
end;

Operator + (a: Vector; b: Vector) plusvector : Vector;
begin
	plusvector.x := a.x + b.x;
	plusvector.y := a.y + b.y;
end;

Operator - (a: Vector; b: Vector) diff : Vector;
begin
	diff := a + (-b);
end;

Operator * (a: Vector; b: double) scalevector : Vector;
begin
	scalevector.x := a.x * b;
	scalevector.y := a.y * b;
end;

Operator * (a: double; b: Vector) scalevector : Vector;
begin
	scalevector := b * a;
end;

{ Rect functions }

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

function distance_point_line(p: Vector; l: Rect) : double;
begin
	distance_point_line :=
		(l.p1.y - l.p2.y) * p.x +
		(l.p2.x - l.p1.x) * p.y +
		l.p1.x * l.p2.y + l.p2.x * l.p1.y;
	distance_point_line := abs(distance_point_line);
	distance_point_line := distance_point_line /
		sqrt(intpower(l.p1.y - l.p2.y, 2) + intpower(l.p2.x - l.p1.x, 2));
end;

function point_in_rect(p: Vector; r: Rect) : Boolean;
begin	
	rect_normalize(r);
	point_in_rect :=
		(r.p1.x < p.x) and (p.x < r.p2.x) and
		(r.p1.y < p.y) and (p.y < r.p2.y);
end;

function collision_point_segment(p: Vector; var s: Rect; radius: double) : Boolean;
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

function collision_field_segment(x, y: integer; var s: Rect) : Boolean;
begin
	collision_field_segment := collision_point_segment(v(x + 0.5, y + 0.5),
		s, COLLISION_RADIUS);
end;


begin
end.
