unit CrtInterface;

interface
uses Game, Types, Geometry, Lists, Crt;

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
	end;

	ABInterface = record
		width, height: integer;
		view: ViewPort;
		gc: pGameController;
		paneltl, paneltc, paneltr, panelbl, panelbc, panelbr: ansistring;
		exitting: boolean;
		tpanel_needs_update, bpanel_needs_update: boolean;
	end;

procedure new_abinterface(var iface: ABInterface; gc: pGameController);
procedure iface_redraw(var iface: ABInterface);
procedure iface_step(var iface: ABInterface);
procedure write_panel(var iface: ABInterface; pan: WhichPanel; place: WhichPlace; s: ansistring);


implementation
uses StaticConfig,
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
	Enter = chr(13);
	Escape = chr(27);

Operator =(a, b: CharOnScreen) eq : boolean;
begin
	eq := (a.colors = b.colors) and (a.ch = b.ch);
end;

{ Chech the terminal dimensions }
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


procedure new_viewport(var view: ViewPort; x, y: integer);
begin
	view.origin := iv(x, y);
	view.height := 0;
	view.width := 0;
	view.needs_redraw := True;
end;

procedure resize_viewport(var view: ViewPort; w, h: integer);
begin
	if (w > view.width) or (h > view.height) then
		setlength(view.screen, w, h);
	view.width := w;
	view.height := h;
end;

{ Checks if a point can be rendered within a viewport }
function point_in_viewport(var view: ViewPort; p: IntVector) : boolean;
begin
	point_in_viewport := (p.x >= 0) and (p.x < view.width) and
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

procedure new_abinterface(var iface: ABInterface; gc: pGameController);
begin
	new_viewport(iface.view, 0, 0);
	iface.width := 0;
	iface.height := 0;
	iface.gc := gc;
	iface.exitting := False;
	iface.tpanel_needs_update := True;
	iface.bpanel_needs_update := True;
end;

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

procedure revert_standard_colors;
begin
	TextBackground(Black);
	TextColor(White);
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
	TextBackground(White);
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

{ Returns what char should be at position (x, y) relative to the origin of viewport }
function render_field(var iface: ABInterface; x, y: integer) : CharOnScreen;
var
	field_pos: IntVector;
begin
	field_pos := viewport_to_field_position(iface.view, iv(x, y));
	if (field_pos.x < 0) or (field_pos.x > iface.gc^.pc^.field^.width - 1) or
		(field_pos.y < 0) or (field_pos.y > iface.gc^.pc^.field^.height - 1) then
	begin
		render_field.ch := ' ';
		render_field.colors := (Black << 4) or White;
		exit;
	end;
	
	case trunc(iface.gc^.pc^.field^.arr[field_pos.x, field_pos.y].current_hp) of
	0:
		render_field.ch := CH[0];
	1..10:
		render_field.ch := CH[1];
	11..20:
		render_field.ch := CH[2];
	21..30:
		render_field.ch := CH[3];
	31..40:
		render_field.ch := CH[4];
	41..50:
		render_field.ch := CH[5];
	51..60:
		render_field.ch := CH[6];
	61..70:
		render_field.ch := CH[7];
	71..80:
		render_field.ch := CH[8];
	81..90:
		render_field.ch := CH[9];
	91..100:
		render_field.ch := CH[10];
	end;

	render_field.colors := (Black << 4) or Green;
end;

{ Prints a char to the screen }
procedure viewport_putchar(view: ViewPort; pos: IntVector; c: CharOnScreen; force: boolean);
begin
	if (view.screen[pos.x, pos.y] <> c) or force then
	begin
		view.screen[pos.x, pos.y] := c;
		GotoXY(pos.x + 1, pos.y + 2);
		TextBackground(c.colors >> 4);
		TextColor(c.colors and $0f);
		write(c.ch);
	end;
end;

function render_rocket(var iface: ABInterface; r: Rocket) : CharOnScreen;
begin
	render_rocket.colors := (Black << 4) or Red;
	render_rocket.ch := '@';
end;

{ Draws all the rockets on the screen }
procedure rockets_draw(var iface: ABInterface);
var
	cur: pRocketNode;
	c: CharOnScreen;
	pos: IntVector;
begin
	cur := iface.gc^.pc^.rockets.head;
	while cur <> nil do
	begin
		pos := field_to_viewport_position(iface.view, iv(cur^.v.position));
		if point_in_viewport(iface.view, pos) and not cur^.v.removed then
		begin
			c := render_rocket(iface, cur^.v);
			viewport_putchar(iface.view, pos, c, True);
		end;
		cur := cur^.next;
	end;
end;

{ Does a full redraw of the viewport part of screen }
procedure iface_redraw_viewport(var iface: ABInterface);
var
	c: CharOnScreen;
	i, j: integer;
begin
	for j := 0 to iface.view.height - 1 do
	begin
		for i := 0 to iface.view.width - 1 do
		begin
			c := render_field(iface, i, j);
			iface.view.screen[i, j] := c;
			viewport_putchar(iface.view, iv(i, j), c, True);
		end;
	end;
	iface.view.needs_redraw := False;
	rockets_draw(iface);
end;

procedure iface_redraw(var iface: ABInterface);
begin
	revert_standard_colors;
	{ Update the panels }
	update_panel(iface, Top);
	update_panel(iface, Bottom);
	iface_redraw_viewport(iface);
	GotoXY(1, 1);
end;

procedure viewport_update_field(var iface: ABInterface);
var
	cur: pIntVectorNode;
	c: CharOnScreen;
	pos_viewport: IntVector;
begin
	cur := iface.gc^.pc^.animlist.head;
	while cur <> nil do
	begin
		{ Find where the field is in the viewport }
		pos_viewport := field_to_viewport_position(iface.view, cur^.v);
		if point_in_viewport(iface.view, pos_viewport) then
		begin
			c := render_field(iface, pos_viewport.x, pos_viewport.y);
			viewport_putchar(iface.view, pos_viewport, c, False);
		end;
		cur := cur^.next;
	end;
	GotoXY(1, 1);
end;

procedure viewport_update_rockets(iface: ABInterface);
var
	cur: pRocketNode;
	c: CharOnScreen;
	under: CharOnScreen;
	pos: IntVector;
begin
	cur := iface.gc^.pc^.rockets.head;
	while cur <> nil do
	begin
		c := render_rocket(iface, cur^.v);
		pos := field_to_viewport_position(iface.view, iv(cur^.v.position));
		if point_in_viewport(iface.view, pos) and not cur^.v.removed then
			viewport_putchar(iface.view, pos, c, False);
		pos := field_to_viewport_position(iface.view, iv(cur^.v.oldpos));
		if point_in_viewport(iface.view, pos) then
		begin
			under := render_field(iface, pos.x, pos.y);
			viewport_putchar(iface.view, pos, under, False);
		end;
		cur := cur^.next;
	end;
	GotoXY(1,1);
end;


procedure viewport_update(var iface: ABInterface);
begin
	viewport_update_field(iface);
	viewport_update_rockets(iface);
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

procedure read_input(var iface: ABInterface);
var
	c, prev: char;
begin
	if not KeyPressed then
		exit;
	c := chr(255);
	while KeyPressed do
	begin
		prev := c;
		c := ReadKey;
	end;
	if prev = chr(0) then
		{ Temporary. FIXME: substitute with aiming }
		case c of
		ALeft:
			viewport_move(iface.view, iv(-1, 0));
		ARight:
			viewport_move(iface.view, iv(1, 0));
		AUp:
			viewport_move(iface.view, iv(0, -1));
		ADown:
			viewport_move(iface.view, iv(0, 1));
		end
	else
		case c of
			Escape: iface.exitting := True;
			'w': viewport_move(iface.view, iv(0, -5));
			'a': viewport_move(iface.view, iv(-5, 0));
			's': viewport_move(iface.view, iv(0, 5));
			'd': viewport_move(iface.view, iv(5, 0));
		end;
	{ FIXME: add support for other buttons }
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
		iface_redraw_viewport(iface)	
	else
		{ Perform normal update }
		iface_update(iface);

	read_input(iface);
end;

begin
end.
