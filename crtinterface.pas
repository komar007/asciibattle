unit CrtInterface;

interface
uses Game, Geometry;

type
	WhichPanel = (Top, Bottom);

	ViewPort = record
		anchor: IntVector;
		width, height: integer;
	end;

	ABInterface = record
		width, height: integer;
		view: ViewPort;
		gc: pGameController;
		paneltl, paneltc, paneltr, panelbl, panelbc, panelbr: string;
	end;

procedure new_abinterface(var iface: ABInterface; gc: pGameController);
procedure update_panel(var iface: ABInterface; w: WhichPanel; left, center, right: string);
procedure iface_redraw(var iface: ABInterface);
procedure iface_step(var iface: ABInterface);


implementation
uses Crt, StaticConfig,
{$ifdef LINUX}
	termio, BaseUnix,
{$endif}
	strutils, math;


type
	CharOnScreen = record
		colors: byte;
		ch: char;
	end;

procedure ScreenSize(var x, y: integer);
var
{$ifdef LINUX}
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
	view.anchor := iv(x, y);
	view.height := 0;
	view.width := 0;
end;

procedure new_abinterface(var iface: ABInterface; gc: pGameController);
begin
	new_viewport(iface.view, 0, 0);
	iface.width := 0;
	iface.height := 0;
	iface.gc := gc;
end;

function template_width(t: string) : integer;
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

procedure write_template(t: string; char_limit: integer);
var
	len: integer;
	s: string;
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

procedure update_panel(var iface: ABInterface; w: WhichPanel; left, center, right: string);
var
	i: integer;
	pos_y: integer;
	old_x, old_y: integer;
	center_start, right_start: integer;
begin
	old_x := WhereX;
	old_y := WhereY;
	if w = Top then
		pos_y := 1
	else
		pos_y := iface.height;
	GotoXY(1, pos_y);
	TextBackground(White);
	TextColor(Black);
	{ Fill the panel with white background }
	for i := 1 to iface.width do
		write(' ');

	GotoXY(1, pos_y);
	write_template(left, iface.width);
	center_start := max(1, (iface.width - template_width(center)) div 2 + 1);
	GotoXY(center_start, pos_y);
	write_template(center, iface.width - center_start + 1);
	right_start := max(1, iface.width - template_width(right) + 1);
	GotoXY(right_start, pos_y);
	write_template(right, iface.width - right_start + 1);

	revert_standard_colors;
	GotoXY(old_x, old_y);
end;

function render_char(var iface: ABInterface; x, y: integer) : CharOnScreen;
var
	real_pos: IntVector;
begin
	real_pos := iv(x, y) + iface.view.anchor;
	if (real_pos.x < 0) or (real_pos.x > iface.gc^.pc^.field^.width - 1) or
		(real_pos.y < 0) or (real_pos.y > iface.gc^.pc^.field^.height - 1) then
	begin
		render_char.ch := ' ';
		render_char.colors := (Black << 4) or White;
		exit;
	end;
	
	case trunc(iface.gc^.pc^.field^.arr[real_pos.x, real_pos.y].current_hp) of
	0:
		render_char.ch := CH[0];
	1..10:
		render_char.ch := CH[1];
	11..20:
		render_char.ch := CH[2];
	21..30:
		render_char.ch := CH[3];
	31..40:
		render_char.ch := CH[4];
	41..50:
		render_char.ch := CH[5];
	51..60:
		render_char.ch := CH[6];
	61..70:
		render_char.ch := CH[7];
	71..80:
		render_char.ch := CH[8];
	81..90:
		render_char.ch := CH[9];
	91..100:
		render_char.ch := CH[10];
	end;

	render_char.colors := (Black << 4) or Green;
end;

procedure iface_redraw_viewport(var iface: ABInterface);
var
	c: CharOnScreen;
	i, j: integer;
begin
	GotoXY(1, 2);
	for j := 0 to iface.view.height - 1 do
	begin
		for i := 0 to iface.view.width - 1 do
		begin
			c := render_char(iface, i, j);
			TextBackground(c.colors >> 4);
			TextColor(c.colors and $0f);
			write(c.ch);
		end;
		writeln;
	end;
end;

procedure iface_redraw(var iface: ABInterface);
begin
	revert_standard_colors;
	{ Update the panels }
	update_panel(iface, Top, iface.paneltl, iface.paneltc, iface.paneltr);
	update_panel(iface, Bottom, iface.panelbl, iface.panelbc, iface.panelbr);

	iface_redraw_viewport(iface);
end;

procedure iface_step(var iface: ABInterface);
var
	old_w, old_h: integer;
begin
	old_w := iface.width;
	old_h := iface.height;
	ScreenSize(iface.width, iface.height);
	if (old_w <> iface.width) or (old_h <> iface.height) or True then
	begin
		{ Recalculate viewport dimensions }
		iface.view.width := iface.width;
		iface.view.height := iface.height - 2;
		{ Redraw the whole screen }
		clrscr; { temporary! }
		iface_redraw(iface);
	end
	else
	begin
		{ Perform normal update }
		exit;
	end;
end;

begin
end.
