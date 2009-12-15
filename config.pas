unit Config;

interface
uses Physics, StaticConfig;

function parse_battlefield_string(var field: BattleField; field_str: ansistring) : integer;

implementation

{ Auxiliary function used by parse_num }
function numeric(c: char) : boolean;
begin
	numeric := ((ord(c) >= ord('0')) and (ord(c) <= ord('9'))) or (c = '-');
end;

{ parses a number in string from position l[s], leaves the number in num, returns the first non-digit }
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

function parse_battlefield_string(var field: BattleField; field_str: ansistring) : integer;
var
	i: integer;
	len: integer;
	el_type: integer;
	w, h, x, y: integer;
begin
	i := parse_num(field_str, 1, w);
	i := parse_num(field_str, i, h);

	if (field.width < w) or (field.height < h) then
	begin
		parse_battlefield_string := -1;
		exit;
	end;

	len := length(field_str);
	x := 0; y := 0;
	for i := i to len do
	begin
		if numeric(field_str[i]) then
		begin
			el_type := ord(field_str[i]) - ord('0');
			field.arr[x, y].hp := INITIAL_HP[el_type];
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
