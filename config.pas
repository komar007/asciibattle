unit Config;

interface
uses BattleField, Geometry, StaticConfig, Types, Lists;

const
	NEWLINE = chr(10);

type
	ErrorCode = record
		code: (OK, FILE_ERROR, BFIELD_OVERFLOW, PARSE_ERROR, INCOMPL_BFIELD, INCOMPL_PAIR, INVALID_KEY, MISSING_KEY);
		msg: ansistring;
	end;

	ConfigStruct = record
		bfield_file: ansistring;
		fort_modifier: double;
		max_force: double;
		max_wind: double;
		fort_file: array [1..2] of ansistring;
		fort_pos: array [1..2] of IntVector;
		name: array[1..2] of ansistring;
		color: array[1..2] of shortint;
	end;

function parse_bfield_dimensions(var field_str: ansistring; var w, h: integer; var nextpos: integer) : ErrorCode;
function parse_bfield_dimensions(var field_str: ansistring; var w, h: integer) : ErrorCode;
function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring; var cannon, king: IntVector; modifier: double; owner: integer) : ErrorCode;
function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring; modifier: double; owner: integer) : ErrorCode;
function read_file_to_string(filename: ansistring; var ostr: ansistring) : ErrorCode;
function parse_game_string(var options: ansistring; var config: ConfigStruct) : ErrorCode;


implementation
uses SysUtils, strutils;


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
	parse_bfield_dimensions.code := OK;
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
end;

function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring; modifier: double; owner: integer) : ErrorCode;
var
	cannon, king: IntVector;
begin
	parse_bfield_string := parse_bfield_string(field, origin, field_str, cannon, king, modifier, owner);
end;

function parse_bfield_string(var field: BField; origin: IntVector; var field_str: ansistring; var cannon, king: IntVector; modifier: double; owner: integer) : ErrorCode;
var
	i: integer;
	len: integer;
	el_type: integer;
	w, h, x, y: integer;
	wx, wy: integer;
	err: ErrorCode;
begin
	parse_bfield_string.code := OK;
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
		if numeric(field_str[i]) or (field_str[i] in ['.', 'C', 'K']) then
		begin
			wx := x + origin.x;
			wy := y + origin.y;
			field.arr[wx, wy].owner := owner;
			el_type := ord(field_str[i]) - ord('0');
			{ Omit the dot which means `transparent' } 
			if numeric(field_str[i]) then
				field.arr[wx, wy].hp := INITIAL_HP[el_type] * modifier
			else if field_str[i] in ['C', 'K'] then
				field.arr[wx, wy].hp := INITIAL_KING_HP;
			if field_str[i] = 'C' then
				cannon := iv(x, y);
			if field_str[i] = 'K' then
				king := iv(x, y);
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
		else if is_whitespace(field_str[i]) then
			continue
		else
		begin
			parse_bfield_string.code := PARSE_ERROR;
			parse_bfield_string.msg := 'Malformed field file at byte ' + IntToStr(i) + 
				': got: `' + field_str[i] + ''', expected digit, `K'', `C'' or `.''';
			exit;
		end;
	end;
	if (y * w + x) < (w * h) then
	begin
		parse_bfield_string.code := INCOMPL_BFIELD;
		parse_bfield_string.msg := 'The field is incomplete. Got ' + IntToStr(y * w + x) +
			' characters, expected ' + IntToStr(w * h);
	end
end;

function read_file_to_string(filename: ansistring; var ostr: ansistring) : ErrorCode;
var
	fp: text;
	t: ansistring;
begin
	read_file_to_string.code := OK;
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

function parse_keys(var pairs: ConfigPairList; var confstr: ansistring) : ErrorCode;
var
	pair: ConfigPair;
	len: integer;
	i, l: integer;
begin
	parse_keys.code := OK;
	len := length(confstr);
	i := 0;
	l := 1;
	while i <= len do
	begin
		pair.key := '';
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
				pair.key := pair.key + confstr[i];
			inc(i);
		end;
		if (i > len) or (confstr[i] = NEWLINE) then
		begin
			parse_keys.code := INCOMPL_PAIR;
			parse_keys.msg := 'Incomplete key-value pair in line: ' + IntToStr(l);
			exit;
		end;
		inc(i); pair.value := '';
		while (i <= len) and (confstr[i] <> NEWLINE) do
		begin
			if is_sensible(confstr[i]) then
				pair.value := pair.value + confstr[i];
			inc(i);
		end;	
		pair.value := trim(pair.value);
		pair.key := trim(pair.key);
		if pair.value = '' then
		begin
			parse_keys.code := INCOMPL_PAIR;
			parse_keys.msg := 'Empty value in line: ' + IntToStr(l);
			exit;
		end;
		pair.line := l;
		push_front(pairs, pair);
	end;
end;

function parse_game_string(var options: ansistring; var config: ConfigStruct) : ErrorCode;
var
	list: ConfigPairList;
	cur: pConfigPairNode;
	err: ErrorCode;
	what: ansistring;
	num: integer;
	i: integer;
begin
	config.fort_modifier := 2;
	config.max_force := 30;
	config.max_wind := 4;
	config.name[1] := 'Player 1';
	config.name[2] := 'Player 2';
	config.color[1] := 2;  {Green}
	config.color[2] := 14; {Yellow}
	config.fort_pos[1] := iv(0, 0);
	config.fort_pos[2] := iv(0, 0);
	parse_game_string.code := OK;
	new_list(list);
	err := parse_keys(list, options);
	if err.code <> OK then
	begin
		parse_game_string := err;
		exit;
	end;
	cur := list.head;
	while cur <> nil do
	begin
		if cur^.v.key = 'bfield_file' then
			config.bfield_file := cur^.v.value
		else if cur^.v.key = 'fort_modifier' then
			config.fort_modifier := StrToFloat(cur^.v.value)
		else if cur^.v.key = 'max_force' then
			config.max_force := StrToFloat(cur^.v.value)
		else if cur^.v.key = 'max_wind' then
			config.max_wind := StrToFloat(cur^.v.value)
		else if (length(cur^.v.key) >= 8) and
			AnsiStartsStr('player', cur^.v.key) and (cur^.v.key[7] in ['1', '2']) then
		begin
			num := ord(cur^.v.key[7]) - ord('0');
			what := AnsiMidStr(cur^.v.key, 9, 100000);
			if what = 'fort_file' then
				config.fort_file[num] := cur^.v.value
			else if what = 'name' then
				config.name[num] := cur^.v.value
			else if what = 'fort_pos' then
			begin
				i := parse_num(cur^.v.value, 1, config.fort_pos[num].x);
				parse_num(cur^.v.value, i, config.fort_pos[num].y);
			end
			else if what = 'color' then
				config.color[num] := StrToInt(cur^.v.value)
			else
			begin
				parse_game_string.code := INVALID_KEY;
				parse_game_string.msg := 'Invalid player description key `' + cur^.v.key + ''' in line ' + IntToStr(cur^.v.line);
				break;
			end;
		end
		else
		begin
			parse_game_string.code := INVALID_KEY;
			parse_game_string.msg := 'Invalid key `' + cur^.v.key + ''' in line ' + IntToStr(cur^.v.line);
			break;
		end;
		cur := cur^.next;
	end;
	if config.bfield_file = '' then
	begin
		parse_game_string.code := MISSING_KEY;
		parse_game_string.msg := 'Missing key bfield_file';
	end;
	if config.fort_file[1] = '' then
	begin
		parse_game_string.code := MISSING_KEY;
		parse_game_string.msg := 'Missing key player1_fort_file';
	end;
	if config.fort_file[2] = '' then
	begin
		parse_game_string.code := MISSING_KEY;
		parse_game_string.msg := 'Missing key player2_fort_file';
	end;
end;

begin
end.
