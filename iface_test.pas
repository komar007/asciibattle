program asciibattle;
uses CrtInterface;

var
	iface: ABInterface;

begin
	new_abinterface(iface, 0, 0);
	redraw(iface);
	readln;
end.
