unit CrtInterface;

{
h = ScreenHeight
w = ScreenWidth

+--------------------------+
|(1, 1)  Top  panel        +
+--------------------------+
|(1, 2)                    |
|         @                |
|                    @     |
|         Viewport         |
|                   #@##   |
|  #$#$           @@#@$@$  |
|#$$##$          @   @#@$  |
+--------------------------+
|(1, h) Bottom panel       |
+--------------------------+

}

interface
uses Game, Geometry;

type
	WhichPanel = (Top, Bottom);
	WhichPlace = (Left, Center, Right);

	{ 2-byte interpretation of a single character on screen with
	  a color and bgcolor }
	CharOnScreen = record
		{ high 4 bits: background, low 4 bits: foreground }
		colors: byte;
		ch: char;
	end;

	ViewPort = record
		{ Where in the battlefield the upper left-hand
		  corner of the viewport is}
		origin: IntVector;
		width, height: integer;
		{ Screen buffer to make sure only necessary updates are made
		  and assure the minimal number of IO operations }
		screen: array of array of CharOnScreen;
		{ Flag }
		needs_update: boolean;
		{ Current position of the sight marker }
		sight_marker: IntVector;
	end;

	ABInterface = record
		width, height: integer;
		view: ViewPort;
		gc: pGameController;
		{ Strings representing what is in 6 sections of panels }
		paneltl, paneltc, paneltr, panelbl, panelbc, panelbr: ansistring;
		{ Flags used by main program }
		exitting, shooting: boolean;
		{ Flags }
		tpanel_needs_update, bpanel_needs_update: boolean;
		player_bar_needs_update, wind_bar_needs_update, force_bar_needs_update, weapon_bar_needs_update: boolean;
		{ The length of the current wind bar }
		wind_bar: integer;
	end;

procedure new_abinterface(var iface: ABInterface; gc: pGameController);
procedure iface_step(var iface: ABInterface);
procedure iface_change_player(var iface: ABInterface; p: integer);


implementation
uses Crt, Lists, Types, Physics, StaticConfig, SysUtils, BattleField,
{$ifdef LINUX}
	termio, BaseUnix,
{$endif}
	strutils, math;


const
	{ Special keycodes }
	ALeft = chr(75);
	ARight = chr(77);
	AUp = chr(72);
	ADown = chr(80);
	{ Normal keycodes }
	Space = ' ';
	Enter = chr(13);
	Escape = chr(27);
	{ Colors }
	BurningColors: array[0..5] of integer = (4, 5, 6, 12, 13, 14);

Operator =(a, b: CharOnScreen) eq : boolean;
begin
	eq := (a.colors = b.colors) and (a.ch = b.ch);
end;

{ Forward declarations }
procedure viewport_update_sight(var iface: ABInterface); forward;
procedure viewport_update_fields(var iface: ABInterface); forward;
procedure viewport_update_rockets(var iface: ABInterface); forward;
function sight_marker_pos(iface: ABInterface) : IntVector; forward;
procedure update_force_bar(var iface: ABInterface); forward;
procedure update_weapon_bar(var iface: ABInterface); forward;
procedure update_panel(var iface: ABInterface; w: WhichPanel); forward;
procedure count_wind_bar(var iface: ABInterface); forward;
procedure update_wind_bar(var iface: ABInterface); forward;
procedure update_players_bar(var iface: ABInterface); forward;
procedure write_panel(var iface: ABInterface; pan: WhichPanel; place: WhichPlace; s: ansistring); forward;
procedure iface_update(var iface: ABInterface); forward;
procedure iface_redraw(var iface: ABInterface); forward;
procedure read_input(var iface: ABInterface); forward;
function render_field(var iface: ABInterface; p: IntVector) : CharOnScreen; forward;
function render_rocket(var iface: ABInterface; r: Rocket) : CharOnScreen; forward;
procedure revert_standard_colors; forward;
procedure ScreenSize(var x, y: integer); forward;

{ ************************ Viewport Section ************************ }

procedure new_viewport(var view: ViewPort; x, y: integer);
begin
	view.origin := iv(x, y);
	view.height := 0;
	view.width := 0;
	view.needs_update := True;
end;

{ Changes the size of viewport and resizes the buffer array, if necessary }
procedure resize_viewport(var view: ViewPort; w, h: integer);
begin
	if (w > view.width) or (h > view.height) then
		setlength(view.screen, w, h);
	view.width := w; view.height := h;
end;

{ Checks if a point can be rendered in a viewport }
function field_in_viewport(var view: ViewPort; p: IntVector) : boolean;
begin
	field_in_viewport := (p.x >= 0) and (p.x < view.width) and
		(p.y >= 0) and (p.y < view.height);
end;

{ Finds the position of a point in the battlefield basing on
  its position in the viewport }
function viewport_to_field_position(var view: ViewPort; p: IntVector) : IntVector;
begin
	viewport_to_field_position := p + view.origin;
end;

{ Checks where to render a field whose position is (x, y) }
function field_to_viewport_position(var view: ViewPort; p: IntVector) : IntVector;
begin
	field_to_viewport_position := p - view.origin;
end;

{ Changes the origin of a viewport }
procedure viewport_move(var view: ViewPort; offset: IntVector);
begin
	view.origin := view.origin + offset;
	view.needs_update := True;
end;

{ Prints a char to the screen }
procedure viewport_putchar(view: ViewPort; pos: IntVector; c: CharOnScreen);
begin
	if field_in_viewport(view, pos) and (view.screen[pos.x, pos.y] <> c) then
	begin
		view.screen[pos.x, pos.y] := c;
		GotoXY(pos.x + 1, pos.y + 2);
		TextBackground(c.colors >> 4);
		TextColor(c.colors and $0f);
		write(c.ch);
	end;
end;

{ Does a full redraw of the viewport part of screen }
procedure viewport_redraw(var iface: ABInterface);
var
	c: CharOnScreen;
	i, j: integer;
begin
	c.ch := chr(255);
	{ Clean screen buffer }
	for j := 0 to iface.view.height - 1 do
		for i := 0 to iface.view.width - 1 do
			iface.view.screen[i, j] := c;
	for j := 0 to iface.view.height - 1 do
	begin
		for i := 0 to iface.view.width - 1 do
		begin
			c := render_field(iface, iv(i, j));
			viewport_putchar(iface.view, iv(i, j), c);
		end;
	end;
	viewport_update_rockets(iface);
	iface.view.needs_update := False;
end;

{ Updates the viewport selectively }
procedure viewport_update(var iface: ABInterface);
begin
	viewport_update_fields(iface);
	viewport_update_rockets(iface);
	viewport_update_sight(iface);
end;

{ Redraws the fields which are being animated }
procedure viewport_update_fields(var iface: ABInterface);
var
	cur: pIntVectorNode;
	c: CharOnScreen;
	pos_viewport: IntVector;
begin
	cur := iface.gc^.pc^.animlist.head;
	while cur <> nil do
	begin
		pos_viewport := field_to_viewport_position(iface.view, cur^.v);
		c := render_field(iface, pos_viewport);
		if gc_field_is_king(iface.gc^, cur^.v) then
			iface.player_bar_needs_update := True;
		viewport_putchar(iface.view, pos_viewport, c);
		cur := cur^.next;
	end;
	GotoXY(1, 1);
end;

{ Redraws all rockets }
procedure viewport_update_rockets(var iface: ABInterface);
var
	cur: pRocketNode;
	c: CharOnScreen;
	pos: IntVector;
begin
	cur := iface.gc^.pc^.rockets.head;
	while cur <> nil do
	begin
		pos := field_to_viewport_position(iface.view, iv(cur^.v.oldpos));
		c := render_field(iface, pos);
		viewport_putchar(iface.view, pos, c);
		pos := field_to_viewport_position(iface.view, iv(cur^.v.position));
		c := render_rocket(iface, cur^.v);
		if not cur^.v.removed then
			viewport_putchar(iface.view, pos, c);
		cur := cur^.next;
	end;
	GotoXY(1,1);
end;

procedure viewport_update_sight(var iface: ABInterface);
var
	oview_pos, nview_pos: IntVector;
	c: CharOnScreen;
begin
	oview_pos := field_to_viewport_position(iface.view, iface.view.sight_marker);
	nview_pos := field_to_viewport_position(iface.view, sight_marker_pos(iface));
	if oview_pos <> nview_pos then
	begin
		c := render_field(iface, oview_pos);
		viewport_putchar(iface.view, oview_pos, c);
		c := render_field(iface, nview_pos);
		viewport_putchar(iface.view, nview_pos, c);
		iface.view.sight_marker := sight_marker_pos(iface);
		GotoXY(1,1);
	end;
end;

{ Changes the angle of sight }
procedure viewport_move_sight(var iface: ABInterface; delta: double);
var
	current_player: pPlayer;
begin
	current_player := @iface.gc^.player[iface.gc^.current_player];
	if gc_player_side(iface.gc^, iface.gc^.current_player) = FortLeft then
		current_player^.angle := current_player^.angle - delta
	else
		current_player^.angle := current_player^.angle + delta;
end;

{ Calculates the position of sight marker }
function sight_marker_pos(iface: ABInterface) : IntVector;
var
	current_player: pPlayer;
begin
	current_player := @iface.gc^.player[iface.gc^.current_player];
	sight_marker_pos := iv(fc(current_player^.cannon) +
		v(cos(current_player^.angle) * SIGHT_LEN,
		  sin(current_player^.angle) * SIGHT_LEN));
end;

{ ************************ Interface Section ************************ }

procedure new_abinterface(var iface: ABInterface; gc: pGameController);
begin
	new_viewport(iface.view, 0, 0);
	iface.width := 0;
	iface.height := 0;
	iface.gc := gc;
	iface.exitting := False;
	iface.shooting := False;
	iface.tpanel_needs_update := True;
	iface.bpanel_needs_update := True;
	iface.player_bar_needs_update := True;
	iface.wind_bar_needs_update := True;
	iface.force_bar_needs_update := True;
	iface.view.sight_marker := sight_marker_pos(iface);
	iface.wind_bar := 0;
end;

{ Performs a single step of the interface processing loop }
procedure iface_step(var iface: ABInterface);
var
	old_w, old_h: integer;
begin
	old_w := iface.width;
	old_h := iface.height;
	ScreenSize(iface.width, iface.height);
	count_wind_bar(iface);
	if (old_w <> iface.width) or (old_h <> iface.height) then
	begin
		{ Recalculate viewport dimensions }
		resize_viewport(iface.view, iface.width, iface.height - 2);
		{ Redraw the whole screen }
		iface_redraw(iface);
	end
	else if iface.view.needs_update then
		viewport_redraw(iface)	
	else
		{ Perform normal update }
		iface_update(iface);
	read_input(iface);
end;

{ Changes the player and updates what needs to be updated in such a case }
procedure iface_change_player(var iface: ABInterface; p: integer);
var
	cp: pPlayer;
begin
	gc_change_player(iface.gc^, p);
	cp := @iface.gc^.player[iface.gc^.current_player];
	iface.force_bar_needs_update := True;
	iface.player_bar_needs_update := True;
	if not gc_player_has_weapon(iface.gc^, iface.gc^.current_player, cp^.current_weapon) then
	begin
		cp^.current_weapon := 1;
		while (cp^.current_weapon < 9) and
			not gc_player_has_weapon(iface.gc^, iface.gc^.current_player, cp^.current_weapon) do
			inc(cp^.current_weapon);
		if not gc_player_has_weapon(iface.gc^, iface.gc^.current_player, cp^.current_weapon) then
			cp^.current_weapon := 0;
	end;
	iface.weapon_bar_needs_update := True;
end;

procedure iface_change_force(var iface: ABInterface; delta: double);
var
	current_player: pPlayer;
begin
	current_player := @iface.gc^.player[iface.gc^.current_player];
	current_player^.force := max(0, min(current_player^.max_force, current_player^.force + delta));
	iface.force_bar_needs_update := True;
end;

procedure iface_change_weapon(var iface: ABInterface; w: integer);
var
	current_player: pPlayer;
begin
	current_player := @iface.gc^.player[iface.gc^.current_player];
	if gc_player_has_weapon(iface.gc^, iface.gc^.current_player, w) then
	begin
		current_player^.current_weapon := w;
		iface.weapon_bar_needs_update := True;
	end;
end;

{ Redraws the whole screen }
procedure iface_redraw(var iface: ABInterface);
begin
	revert_standard_colors;
	viewport_redraw(iface);
	{ Update the panels }
	update_force_bar(iface);
	update_wind_bar(iface);
	update_weapon_bar(iface);
	update_panel(iface, Top);
	update_panel(iface, Bottom);
	GotoXY(1, 1);
end;

procedure iface_update(var iface: ABInterface);
begin
	revert_standard_colors;
	viewport_update(iface);
	if iface.wind_bar_needs_update then
		update_wind_bar(iface);
	if iface.player_bar_needs_update then
		update_players_bar(iface);
	if iface.force_bar_needs_update then
		update_force_bar(iface);
	if iface.weapon_bar_needs_update then
		update_weapon_bar(iface);
	if iface.tpanel_needs_update then
		update_panel(iface, Top);
	if iface.bpanel_needs_update then
		update_panel(iface, Bottom);
end;

{ Conts the integer version of wind force used to represent wind in the interface }
procedure count_wind_bar(var iface: ABInterface);
var
	old_wind: integer;
	maxl: integer;
begin
	old_wind := iface.wind_bar;
	maxl := iface.width div 8;
	if abs(iface.gc^.max_wind) = 0 then
		iface.wind_bar := 0
	else
		iface.wind_bar := trunc(iface.gc^.pc^.wind.x / iface.gc^.max_wind * maxl);
	if iface.wind_bar <> old_wind then
		iface.wind_bar_needs_update := True;
end;

{ Rewrites the wind indicator }
procedure update_wind_bar(var iface: ABInterface);
var
	i: integer;
	s: ansistring;
	maxl: integer;
begin
	maxl := iface.width div 8;
	s := 'Wind: ';
	if iface.wind_bar > 0 then
	begin
		s := s + '[';
		for i := 1 to maxl do
			s := s + ' ';
		s := s + '$4|$1';
		for i := 1 to iface.wind_bar do
			s := s + '>';
		for i := 1 to maxl - iface.wind_bar do
			s := s + ' ';
		s := s + '$0]'
	end
	else
	begin
		s := s + '[$1';
		for i := 1 to maxl + iface.wind_bar do
			s := s + ' ';
		for i := 1 to -iface.wind_bar do
			s := s + '<';
		s := s + '$4|$0';
		for i := 1 to maxl do
			s := s + ' ';
		s := s + ']';
	end;
	write_panel(iface, Top, Center, s);
	iface.wind_bar_needs_update := False;
end;

{ Updates information about players - health and who is playing }
procedure update_players_bar(var iface: ABInterface);
var
	pstring: ansistring;
	pl: pPlayer;
	i: integer;
begin
	for i := 1 to 2 do
	begin
		pl := @iface.gc^.player[i];
		pstring := pl^.name + ' (' + IntToStr(gc_player_life(iface.gc^, i)) + ' hp)';
		if i = iface.gc^.current_player then
			pstring := '$4 > $0' + pstring + '$4 <$0 '
		else
			pstring := '   ' + pstring + '   ';
		if gc_player_side(iface.gc^, i) = FortLeft then
			write_panel(iface, Top, Left, pstring) 
		else
			write_panel(iface, Top, Right, pstring);
	end;
	iface.player_bar_needs_update := False;
end;

procedure update_force_bar(var iface: ABInterface);
var
	bar_len, bar_max_len: integer;
	bar: ansistring;
	current_player: pPlayer;
	i: integer;
begin
	current_player := @iface.gc^.player[iface.gc^.current_player];
	bar_max_len := trunc(iface.width / 4);
	bar_len := trunc(bar_max_len * current_player^.force / iface.gc^.max_force);
	bar := 'Force: [';
	for i := 1 to bar_len do
		bar := bar + '=';
	for i := bar_len + 1 to  bar_max_len do
		bar := bar + ' ';
	bar := bar + ']';
	write_panel(iface, Bottom, Left, bar);
	iface.force_bar_needs_update := False;
end;

procedure update_weapon_bar(var iface: ABInterface);
var
	current_player: pPlayer;
	w: pRocket;
	s: ansistring;
begin
	current_player := @iface.gc^.player[iface.gc^.current_player];
	w := @current_player^.equipment[current_player^.current_weapon];
	if gc_player_has_weapon(iface.gc^, iface.gc^.current_player, current_player^.current_weapon) then
	begin
		s := '[$1' + IntToStr(current_player^.current_weapon) + '$0] ' + w^.name;
		s := s + ' r:' + FloatToStr(w^.exp_radius) + ' $4f:' + FloatToStr(w^.exp_force) + '$0';
		if w^.num = -1 then
			s := s + ' (inf)'
		else
			s := s + ' (' + IntToStr(w^.num) + ')';
	end
	else
		s := 'No weapon :(';
	write_panel(iface, Bottom, Right, s);
	iface.weapon_bar_needs_update := False;
end;

{ ************************ Panel Section ************************ }

{ Fills panel buffer, schedules panel update }
procedure write_panel(var iface: ABInterface; pan: WhichPanel; place: WhichPlace; s: ansistring);
begin
	if pan = Top then
	begin
		iface.tpanel_needs_update := True;
		case place of
			Left: iface.paneltl := s;
			Center: iface.paneltc := s;
			Right: iface.paneltr := s;
		end;
	end
	else
	begin
		iface.bpanel_needs_update := True;
		case place of
			Left: iface.panelbl := s;
			Center: iface.panelbc := s;
			Right: iface.panelbr := s;
		end;
	end;
end;

{ Counts the width of a template (counts the characters omitting attribute change characters }
function template_width(t: ansistring) : integer;
var
	len: integer;
	i: integer;
begin
	template_width := 0;
	len := length(t);
	i := 1;
	while i <= len do
	begin
		if t[i] in ['$', '%'] then
			i := i + 2
		else if t[i] = '\' then
		begin
			inc(template_width);
			i := i + 2
		end
		else
		begin
			inc(template_width);
			inc(i);
		end;
	end;
end;

{ Renders the template to the screen }
procedure write_template(t: ansistring; char_limit: integer);
var
	len: integer;
	s: ansistring;
	i: integer;
begin
	len := length(t);
	i := 1;
	while (i <= len) and (char_limit <> 0) do
	begin
		case t[i] of
			'$': begin
				s := t[i+1];
				TextColor(Hex2Dec(s));
				i := i + 2;
			end;
			'%': begin
				s := t[i+1];
				TextBackground(Hex2Dec(s));
				i := i + 2;
			end;
			'\': begin
				write(t[i+i]);
				dec(char_limit);
				i := i + 2
			end;
			else begin
				write(t[i]);
				dec(char_limit);
				inc(i);
			end;
		end;
	end;
end;

{ Draws the whole panel to the screen }
procedure update_panel(var iface: ABInterface; w: WhichPanel);
var
	i: integer;
	pos_y: integer;
	old_x, old_y: integer;
	center_start, right_start: integer;
	left, center, right: ^ansistring;
begin
	old_x := WhereX;
	old_y := WhereY;
	if w = Top then
	begin
		pos_y := 1;
		left := @iface.paneltl;
		center := @iface.paneltc;
		right := @iface.paneltr;
		iface.tpanel_needs_update := False;
	end
	else
	begin
		pos_y := iface.height;
		left := @iface.panelbl;
		center := @iface.panelbc;
		right := @iface.panelbr;
		iface.bpanel_needs_update := False;
	end;
	GotoXY(1, pos_y);
	TextBackground(LightGray);
	TextColor(Black);
	{ Fill the panel with white background }
	for i := 1 to iface.width do
		write(' ');

	GotoXY(1, pos_y);
	write_template(left^, iface.width);
	center_start := max(1, (iface.width - template_width(center^)) div 2 + 1);
	GotoXY(center_start, pos_y);
	write_template(center^, iface.width - center_start + 1);
	right_start := max(1, iface.width - template_width(right^) + 1);
	GotoXY(right_start, pos_y);
	write_template(right^, iface.width - right_start + 1);

	revert_standard_colors;
	GotoXY(old_x, old_y);
end;

{ ************************ Input Section ************************ }

procedure read_input(var iface: ABInterface);
var
	c, prev: char;
	i: integer;
begin
	if not KeyPressed then
		exit;
	c := chr(255);
	i := 0;
	while KeyPressed do
	begin
		inc(i);
		prev := c;
		c := ReadKey;
	end;
	if prev = chr(0) then
		case c of
			AUp: viewport_move_sight(iface, 0.1);
			ADown: viewport_move_sight(iface, -0.1);
			ALeft: iface_change_force(iface, -0.5);
			ARight: iface_change_force(iface, 0.5);
		end
	else
	begin
		case c of
			Space: iface.shooting := True;
			Escape: iface.exitting := True;
			'w': viewport_move(iface.view, iv(0, -5));
			'a': viewport_move(iface.view, iv(-5, 0));
			's': viewport_move(iface.view, iv(0, 5));
			'd': viewport_move(iface.view, iv(5, 0));
		end;
		if c in ['1'..'9'] then
			iface_change_weapon(iface, ord(c) - ord('0'));
	end;
end;

{ ************************ Character look Section ************************ }

{ Returns what char should be at position (x, y) relative to the origin of viewport
  Takes into account also the sight marker, kings and castles }
function render_field(var iface: ABInterface; p: IntVector) : CharOnScreen;
var
	field_pos: IntVector;
	which: integer;
	bg: shortint;
	width, height: integer;
	f: BFieldElement;
begin
	width := iface.gc^.pc^.field^.width;
	height := iface.gc^.pc^.field^.height;
	field_pos := viewport_to_field_position(iface.view, p);

	if field_pos = sight_marker_pos(iface) then
	begin
		render_field.ch := '+';
		render_field.colors := (Black << 4) or Blue;
		exit;
	end;
	if (field_pos.x < -1) or (field_pos.x > width) or 
		(field_pos.y < -1) or (field_pos.y > height) then
	begin
		render_field.ch := ' ';
		render_field.colors := (Black << 4) or White;
		exit;
	end;
	if ((field_pos.x = -1) or (field_pos.x = width) or (field_pos.y = height)) then
	begin
		render_field.ch := '%';
		render_field.colors := (Black << 4) or Magenta;
		exit;
	end;
	if (field_pos.y = -1) then
	begin
		render_field.ch := '-';
		render_field.colors := (Black << 4) or DarkGray;
		exit;
	end;
	f := iface.gc^.pc^.field^.arr[field_pos.x, field_pos.y];
	if (field_pos = iface.gc^.player[1].cannon) or (field_pos = iface.gc^.player[2].cannon) then
	begin
		render_field.ch := 'C';
		render_field.colors := (Red << 4) or White;
		exit;
	end;
	if ((field_pos = iface.gc^.player[1].king) or (field_pos = iface.gc^.player[2].king)) and (f.current_hp <> 0) then
	begin
		render_field.ch := 'K';
		render_field.colors := (Black << 4) or Blue;
		exit;
	end;
	bg := (Black << 4);
	which := trunc(f.current_hp);
	if which = 0 then
	begin
		render_field.ch := ' ';
		render_field.colors := (Black << 4) or White;
		exit;
	end;
	render_field.ch := CH[min(10, (which div 15) + 1)];
	if field_animated(iface.gc^.pc^, field_pos) and (f.hp < 40) and (f.hp < f.current_hp) then
		render_field.colors := bg or BurningColors[random(6)]
	else if f.owner > 0 then
		render_field.colors := bg or iface.gc^.player[f.owner].color
	else
	begin
		if which < 9 then
			render_field.colors := bg or DarkGray
		else
			render_field.colors := bg or White;
	end;
end;

function render_rocket(var iface: ABInterface; r: Rocket) : CharOnScreen;
begin
	render_rocket.colors := (Black << 4) or LightRed;
	render_rocket.ch := '@';
end;

{ ************************ Auxilliary Section ************************ }

procedure revert_standard_colors;
begin
	TextBackground(Black);
	TextColor(White);
end;

{ Check the terminal dimensions }
procedure ScreenSize(var x, y: integer);
{$ifdef LINUX}
var
	tw: TWinSize;
begin
	fpioctl(stdinputhandle, TIOCGWINSZ, @tw);
	x := tw.ws_col;
	y := tw.ws_row;
{$else}
begin
	x := ScreenWidth;
	y := ScreenHeight;
{$endif}
end;


begin
end.
