unit Config;

interface
uses BattleField, Geometry, StaticConfig;

const
	NEWLINE = chr(10);

type
	ErrorCode = record
		code: (OK, FILE_ERROR, BFIELD_OVERFLOW, PARSE_ERROR, INCOMPL_BFIELD, INCOMPL_PAIR);
		msg: ansistring;
	end;

	ConfigStruct = record
		a: integer;
	end;

function parse_keys(var conf: ConfigStruct; confstr: ansistring) : ErrorCode;
function parse_bfield_dimensions(var field_str: ansistring; var w, h: integer; var nextpos: integer) : ErrorCode;
function parse_bfield_dimensions(var field_str: ansistring; var w, h: integer) : ErrorCode;
function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring; var cannon, king: IntVector) : ErrorCode;
function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring) : ErrorCode;
function read_file_to_string(filename: ansistring; var ostr: ansistring) : ErrorCode;


implementation
uses SysUtils;


{ Auxiliary function used by parse_num }
function numeric(c: char) : boolean;
begin
	numeric := ((ord(c) >= ord('0')) and (ord(c) <= ord('9'))) or (c = '-');
end;

function is_whitespace(c: char) : boolean;
begin
	is_whitespace := c in [' ', chr(9), NEWLINE, chr(13)];
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
	while (s <= len) and is_whitespace(l[s]) do
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

function parse_bfield_dimensions(var field_str: ansistring; var w, h: integer) : ErrorCode;
var
	nextpos: integer;
begin
	parse_bfield_dimensions := parse_bfield_dimensions(field_str, w, h, nextpos);
end;

function parse_bfield_dimensions(var field_str: ansistring; var w, h: integer; var nextpos: integer) : ErrorCode;
var
	i: integer;
begin
	if (length(field_str) < 5) or not numeric(field_str[1]) then
	begin
		parse_bfield_dimensions.code := PARSE_ERROR;
		parse_bfield_dimensions.msg := 'Parse error: expected battlefield dimensions';
		exit;
	end;
	i := parse_num(field_str, 1, w);
	if (length(field_str) < i + 1) or not numeric(field_str[i + 1]) then
	begin
		parse_bfield_dimensions.code := PARSE_ERROR;
		parse_bfield_dimensions.msg := 'Parse error: expected battlefield dimensions';
		exit;
	end;
	nextpos := parse_num(field_str, i, h);

	if (w = 0) or (h = 0) or (w > MAX_W) or (h > MAX_H) then
	begin
		parse_bfield_dimensions.code := BFIELD_OVERFLOW;
		parse_bfield_dimensions.msg := 'Unsupported field dimensions: ' + IntToStr(w) + ' x ' + IntToStr(h);
	end
	else
		parse_bfield_dimensions.code := OK;
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
	err: ErrorCode;
begin
	err := parse_bfield_dimensions(field_str, w, h, i);
	if err.code <> OK then
	begin
		parse_bfield_string := err;
		exit;
	end;

	if (field.width < w + origin.x) or (field.height < h + origin.y) then
	begin
		parse_bfield_string.code := BFIELD_OVERFLOW;
		parse_bfield_string.msg := 'The fort does not fit in the battlefield';
		exit;
	end;

	len := length(field_str);
	x := 0; y := 0;
	for i := i to len do
	begin
		if numeric(field_str[i]) or (field_str[i] = '.') then
		begin
			{ Omit the dot which means `transparent' } 
			if numeric(field_str[i]) then
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
		else if is_whitespace(field_str[i]) then
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
					': got: `' + field_str[i] + ''', expected digit, `K'', `C'' or `.''';
				exit;
			end;
		end;
	end;
	if (y * w + x) < (w * h) then
	begin
		parse_bfield_string.code := INCOMPL_BFIELD;
		parse_bfield_string.msg := 'The field is incomplete. Got ' + IntToStr(y * w + x) +
			' characters, expected ' + IntToStr(w * h);
	end
	else
		parse_bfield_string.code := OK;
end;

function read_file_to_string(filename: ansistring; var ostr: ansistring) : ErrorCode;
var
	fp: text;
	t: ansistring;
begin
	{$I-}
	assign(fp, filename);
	reset(fp);
	readln(fp, ostr);
	ostr := ostr + NEWLINE;
	while not eof(fp) do begin
		readln(fp, t);
		ostr := ostr + t + NEWLINE;
	end;
	if IOResult <> 0 then
	begin
		read_file_to_string.code := FILE_ERROR;
		read_file_to_string.msg := 'There was a problem reading file: ' + filename + '!';
	end
	else
		read_file_to_string.code := OK;
	{$I+}
end;

function is_separator(a: char) : boolean;
begin
	is_separator := (a = '=');
end;

function is_sensible(a: char) : boolean;
begin
	is_sensible := a in [' '..'~'];
end;

function parse_keys(var conf: ConfigStruct; confstr: ansistring) : ErrorCode;
var
	key, value: ansistring;
	len: integer;
	i, l: integer;
begin
	len := length(confstr);
	i := 0;
	l := 1;
	while i <= len do
	begin
		key := '';
		while (i <= len) and (is_whitespace(confstr[i]) and not (confstr[i] = NEWLINE)) do
			inc(i);
		if (i > len) or (confstr[i] = NEWLINE) then
		begin
			inc(i);
			inc(l);
			continue;
		end;
		while (i <= len) and not (is_separator(confstr[i]) or (confstr[i] = NEWLINE)) do
		begin
			if is_sensible(confstr[i]) then
				key := key + confstr[i];
			inc(i);
		end;
		if (i > len) or (confstr[i] = NEWLINE) then
		begin
			parse_keys.code := INCOMPL_PAIR;
			parse_keys.msg := 'Incomplete key-value pair in line: ' + IntToStr(l);
			exit;
		end;
		inc(i); value := '';
		while (i <= len) and (confstr[i] <> NEWLINE) do
		begin
			if is_sensible(confstr[i]) then
				value := value + confstr[i];
			inc(i);
		end;	
		writeln('Line: ', l, ': Key: ', key, ', Value: ', value, '.');
	end;
end;

begin
end.
