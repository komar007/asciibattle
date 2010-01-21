unit Config;

interface
uses BattleField, Geometry, StaticConfig;

type
	ErrorCode = record
		code: (OK, FILE_ERROR, FIELD_OVERFLOW, PARSE_ERROR, INCOMPLETE_FIELD);
		msg: ansistring;
	end;

function parse_bfield_dimensions(var field_str: ansistring; var w, h: integer) : integer;
function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring; var cannon, king: IntVector) : ErrorCode;
function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring) : ErrorCode;
function read_field_from_file(filename: ansistring; var field_str: ansistring) : ErrorCode;


implementation
uses SysUtils;


{ Auxiliary function used by parse_num }
function numeric(c: char) : boolean;
begin
	numeric := ((ord(c) >= ord('0')) and (ord(c) <= ord('9'))) or (c = '-');
end;

function whitespace(c: char) : boolean;
begin
	whitespace := c in [' ', chr(9), chr(10), chr(13)];
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
	while (s <= len) and whitespace(l[s]) do
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

function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring) : ErrorCode;
var
	cannon, king: IntVector;
begin
	parse_bfield_string := parse_bfield_string(field, origin, field_str, cannon, king);
end;

function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring; var cannon, king: IntVector) : ErrorCode;
var
	i: integer;
	len: integer;
	el_type: integer;
	w, h, x, y: integer;
	wx, wy: integer;
begin
	i := parse_bfield_dimensions(field_str, w, h);

	if (w = 0) or (h = 0) then
	begin
		parse_bfield_string.code := PARSE_ERROR;
		parse_bfield_string.msg := 'Width or height too small or malformed field file''s header';
		exit;
	end;

	if (field.width < w + origin.x) or (field.height < h + origin.y) then
	begin
		parse_bfield_string.code := FIELD_OVERFLOW;
		parse_bfield_string.msg := 'The fort does not fit in the battlefield';
		exit;
	end;

	len := length(field_str);
	x := 0; y := 0;
	for i := i to len do
	begin
		if numeric(field_str[i]) then
		begin
			wx := x + origin.x;
			wy := y + origin.y;
			el_type := ord(field_str[i]) - ord('0');
			field.arr[wx, wy].hp := INITIAL_HP[el_type];
			field.arr[wx, wy].current_hp := field.arr[wx, wy].hp;
			field.arr[wx, wy].previous_hp := field.arr[wx, wy].hp;
			field.arr[wx, wy].hp_speed := 0;
			inc(x);
			if not (x < w) then
			begin
				x := 0;
				inc(y);
			end;
		end
		else if whitespace(field_str[i]) then
			continue
		else
		begin
			if field_str[i] = 'C' then
				cannon := iv(x, y)
			else if field_str[i] = 'K' then
				king := iv(x, y)
			else
			begin
				parse_bfield_string.code := PARSE_ERROR;
				parse_bfield_string.msg := 'Malformed field file at byte ' + IntToStr(i) + 
					': got: `' + field_str[i] + ''', expected digit';
				exit;
			end;
		end;
	end;
	if (y * w + x) < (w * h) then
	begin
		parse_bfield_string.code := INCOMPLETE_FIELD;
		parse_bfield_string.msg := 'The field is incomplete. Got ' + IntToStr(y * w + x) +
			' characters, expected ' + IntToStr(w * h);
	end
	else
		parse_bfield_string.code := OK;
end;

function read_field_from_file(filename: ansistring; var field_str: ansistring) : ErrorCode;
var
	fp: text;
	t: ansistring;
begin
	{$I-}
	assign(fp, filename);
	reset(fp);
	readln(fp, field_str);
	field_str := field_str + ' ';
	while not eof(fp) do begin
		readln(fp, t);
		field_str := field_str + t;
	end;
	if IOResult <> 0 then
	begin
		read_field_from_file.code := FILE_ERROR;
		read_field_from_file.msg := 'There was a problem reading file: ' + filename + '!';
	end
	else
		read_field_from_file.code := OK;
	{$I+}
end;

begin
end.
