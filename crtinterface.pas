unit CrtInterface;

interface

type
	WhichPanel = (Top, Bottom);

	ViewPort = record
		x, y: integer;
		width, height: integer;
	end;

	ABInterface = record
		width, height: integer;
		view: ViewPort;
	end;

procedure new_abinterface(var iface: ABInterface; x, y: integer);
procedure update_panel(var iface: ABInterface; w: WhichPanel; left, center, right: string);
procedure redraw(var iface: ABInterface);


implementation
uses Crt,
{$ifdef LINUX}
	termio, BaseUnix,
{$endif}
	strutils, math;


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


procedure new_viewport(var view: ViewPort; width, height, x, y: integer);
begin
	view.x := x;
	view.y := y;
	view.width := width;
	view.height := height - 2; { 2 for panels }
end;

procedure new_abinterface(var iface: ABInterface; x, y: integer);
begin
	ScreenSize(iface.width, iface.height);
	new_viewport(iface.view, iface.width, iface.height, x, y);
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

procedure revert_standart_colors;
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

	revert_standart_colors;
	GotoXY(old_x, old_y);
end;

procedure redraw(var iface: ABInterface);
begin
	revert_standart_colors;
	{ Update the panels }
	update_panel(iface, Top, ' Player 1', '', '$4>$0Player 2$4<');
	update_panel(iface, Bottom, 'asd', 'def', 'deded');
end;

begin
end.
