unit Config;

interface
uses BattleField, Geometry, StaticConfig;

function parse_bfield_dimensions(var field_str: ansistring; var w, h: integer) : integer;
function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring) : integer;


implementation


{ Auxiliary function used by parse_num }
function numeric(c: char) : boolean;
begin
	numeric := ((ord(c) >= ord('0')) and (ord(c) <= ord('9'))) or (c = '-');
end;

{ parses a number in string from position l[s], leaves the number in num,
returns the position of the first non-digit }
function parse_num(var l: ansistring; s: integer; var num: integer) : integer;
var
	sign, len: integer;
begin
	sign := 1;
	num := 0;
	len := length(l);
	while (s <= len) and not numeric(l[s]) do
		inc(s);
	while (s <= len) and numeric(l[s]) do
	begin
		if l[s] = '-' then
			sign := -1
		else
			num := num * 10 + ord(l[s]) - ord('0');
		inc(s);
	end;
	num := num * sign;
	parse_num := s;
end;	

function parse_bfield_dimensions(var field_str: ansistring; var w, h: integer) : integer;
var
	i: integer;
begin
	i := parse_num(field_str, 1, w);
	parse_bfield_dimensions := parse_num(field_str, i, h);
end;

function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring) : integer;
var
	i: integer;
	len: integer;
	el_type: integer;
	w, h, x, y: integer;
	wx, wy: integer;
	cannon, king: IntVector;
begin
	i := parse_bfield_dimensions(field_str, w, h);

	if (field.width < w + origin.x) or (field.height < h + origin.y) then
	begin
		parse_bfield_string := -1;
		exit;
	end;

	len := length(field_str);
	x := 0; y := 0;
	for i := i to len do
	begin
		if numeric(field_str[i]) then
		begin
			if field_str[i] = 'C' then
				cannon := iv(x, y)
			else if field_str[i] = 'K' then
				king := iv(x, y)
			else
			begin
				wx := x + origin.x;
				wy := y + origin.y;
				el_type := ord(field_str[i]) - ord('0');
				field.arr[wx, wy].hp := INITIAL_HP[el_type];
				field.arr[wx, wy].current_hp := field.arr[wx, wy].hp;
				field.arr[wx, wy].previous_hp := field.arr[wx, wy].hp;
				field.arr[wx, wy].hp_speed := 0;
			end;
			inc(x);
			if not (x < w) then
			begin
				x := 0;
				inc(y);
			end;
		end
	end;
end;

begin
end.
