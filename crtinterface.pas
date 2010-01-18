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
uses Game, Physics, Types, Geometry, Lists, Crt;

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
		needs_redraw: boolean;
		sight_marker: IntVector;
	end;

	ABInterface = record
		width, height: integer;
		view: ViewPort;
		gc: pGameController;
		paneltl, paneltc, paneltr, panelbl, panelbc, panelbr: ansistring;
		exitting, shooting: boolean;
		tpanel_needs_update, bpanel_needs_update: boolean;
	end;

procedure new_abinterface(var iface: ABInterface; gc: pGameController);
procedure iface_step(var iface: ABInterface);


implementation
uses StaticConfig, SysUtils,
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
procedure update_force_bar(var iface: ABInterface); forward;
function sight_marker_pos(iface: ABInterface) : IntVector; forward;
procedure update_panel(var iface: ABInterface; w: WhichPanel); forward;
procedure write_panel(var iface: ABInterface; pan: WhichPanel; place: WhichPlace; s: ansistring); forward;
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
	view.needs_redraw := True;
end;

{ Changes the size of viewport and resizes the buffer array, if necessary }
procedure resize_viewport(var view: ViewPort; w, h: integer);
begin
	if (w > view.width) or (h > view.height) then
		setlength(view.screen, w, h);
	view.width := w;
	view.height := h;
end;

{ Checks if a point can be rendered within a viewport }
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

procedure viewport_move(var view: ViewPort; offset: IntVector);
begin
	view.origin := view.origin + offset;
	view.needs_redraw := True;
end;

{ Prints a char to the screen }
procedure viewport_putchar(view: ViewPort; pos: IntVector; c: CharOnScreen; force: boolean);
begin
	if field_in_viewport(view, pos) and ((view.screen[pos.x, pos.y] <> c) or force) then
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
	for j := 0 to iface.view.height - 1 do
	begin
		for i := 0 to iface.view.width - 1 do
		begin
			c := render_field(iface, iv(i, j));
			viewport_putchar(iface.view, iv(i, j), c, True);
		end;
	end;
	iface.view.needs_redraw := False;
	viewport_update_rockets(iface);
end;

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
		viewport_putchar(iface.view, pos_viewport, c, False);
		cur := cur^.next;
	end;
	GotoXY(1, 1);
end;

{ Updates rockets' positions }
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
		viewport_putchar(iface.view, pos, c, False);
		pos := field_to_viewport_position(iface.view, iv(cur^.v.position));
		c := render_rocket(iface, cur^.v);
		if not cur^.v.removed then
			viewport_putchar(iface.view, pos, c, False);
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
		viewport_putchar(iface.view, oview_pos, c, False);

		c := render_field(iface, nview_pos);
		viewport_putchar(iface.view, nview_pos, c, False);
		GotoXY(1,1);
		iface.view.sight_marker := sight_marker_pos(iface);
	end;
end;

procedure viewport_move_sight(var iface: ABInterface; delta: double);
begin
	if gc_player_side(iface.gc^, iface.gc^.current_player^) = FortLeft then
		iface.gc^.current_player^.angle := iface.gc^.current_player^.angle - delta
	else
		iface.gc^.current_player^.angle := iface.gc^.current_player^.angle + delta;
	viewport_update_sight(iface);
end;

function sight_marker_pos(iface: ABInterface) : IntVector;
begin
	sight_marker_pos := iv(fc(iface.gc^.current_player^.cannon) +
		v(cos(iface.gc^.current_player^.angle) * SIGHT_LEN,
		  sin(iface.gc^.current_player^.angle) * SIGHT_LEN));
end;

procedure viewport_change_force(var iface: ABInterface; delta: double);
begin
	iface.gc^.current_player^.force := max(0, min(iface.gc^.current_player^.max_force, iface.gc^.current_player^.force + delta));
	update_force_bar(iface);
end;

procedure update_force_bar(var iface: ABInterface);
var
	bar_len, bar_max_len: integer;
	bar: ansistring;
	i: integer;
begin
	bar_max_len := trunc(iface.width / 4);
	bar_len := trunc(bar_max_len * iface.gc^.current_player^.force / iface.gc^.current_player^.max_force);
	bar := 'Force: [';
	for i := 1 to bar_len do
		bar := bar + '=';
	for i := bar_len + 1 to  bar_max_len do
		bar := bar + ' ';
	bar := bar + ']';
	write_panel(iface, Bottom, Center, bar);
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
	iface.view.sight_marker := sight_marker_pos(iface);
end;

procedure iface_redraw(var iface: ABInterface);
begin
	revert_standard_colors;
	{ Update the panels }
	update_force_bar(iface);
	update_panel(iface, Top);
	update_panel(iface, Bottom);
	viewport_redraw(iface);
	GotoXY(1, 1);
end;

procedure iface_update(var iface: ABInterface);
begin
	revert_standard_colors;
	if iface.tpanel_needs_update then
		update_panel(iface, Top);
	if iface.bpanel_needs_update then
		update_panel(iface, Bottom);
	viewport_update(iface);
end;

procedure iface_step(var iface: ABInterface);
var
	old_w, old_h: integer;
begin
	old_w := iface.width;
	old_h := iface.height;
	ScreenSize(iface.width, iface.height);
	if (old_w <> iface.width) or (old_h <> iface.height) then
	begin
		{ Recalculate viewport dimensions }
		resize_viewport(iface.view, iface.width, iface.height - 2);
		{ Redraw the whole screen }
		iface_redraw(iface);
	end
	else if iface.view.needs_redraw then
		viewport_redraw(iface)	
	else
		{ Perform normal update }
		iface_update(iface);
	read_input(iface);
end;

{ ************************ Panel Section ************************ }

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

procedure write_template(t: ansistring; char_limit: integer);
var
	len: integer;
	s: ansistring;
	i: integer;
begin
	len := length(t);
	i := 1;
	while (i <= len) and (char_limit <> 0) do
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
	write_panel(iface, Top, Left, IntToStr(i));
	if prev = chr(0) then
		case c of
			AUp: viewport_move_sight(iface, 0.1);
			ADown: viewport_move_sight(iface, -0.1);
			ALeft: viewport_change_force(iface, -0.5);
			ARight: viewport_change_force(iface, 0.5);
		end
	else
		case c of
			Space: iface.shooting := True;
			Escape: iface.exitting := True;
			'w': viewport_move(iface.view, iv(0, -5));
			'a': viewport_move(iface.view, iv(-5, 0));
			's': viewport_move(iface.view, iv(0, 5));
			'd': viewport_move(iface.view, iv(5, 0));
		end;
	{ FIXME: add support for other buttons }
end;

{ ************************ Character look Section ************************ }

{ Returns what char should be at position (x, y) relative to the origin of viewport }
function render_field(var iface: ABInterface; p: IntVector) : CharOnScreen;
var
	field_pos: IntVector;
	which: integer;
	bg: shortint;
begin
	field_pos := viewport_to_field_position(iface.view, p);
	if field_pos = sight_marker_pos(iface) then
	begin
		render_field.ch := '+';
		render_field.colors := (Black << 4) or Blue;
		exit;
	end
	else if (field_pos.x < 0) or (field_pos.x > iface.gc^.pc^.field^.width - 1) or
		(field_pos.y < 0) or (field_pos.y > iface.gc^.pc^.field^.height - 1) then
	begin
		render_field.ch := ' ';
		render_field.colors := (Black << 4) or White;
		exit;
	end;
	bg := (Black << 4);
	which := trunc(iface.gc^.pc^.field^.arr[field_pos.x, field_pos.y].current_hp);
	render_field.ch := CH[which div 10];
	if field_animated(iface.gc^.pc^, field_pos.x, field_pos.y) and
		(iface.gc^.pc^.field^.arr[field_pos.x, field_pos.y].hp < 20) then
		render_field.colors := bg or BurningColors[random(6)]
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
