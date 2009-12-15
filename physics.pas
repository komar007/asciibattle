unit Physics;

interface

type
	Element = record
		hp: integer;
	end;
	Element_ptr = ^Element;

	BattleField = record
		width, height: integer;
		arr: array of array of Element;
	end;

	procedure battlefield_init(var field: BattleField; x, y: integer);

implementation

procedure battlefield_init(var field: BattleField; x, y: integer);
begin
	field.width := x;
	field.height := y;
	setlength(field.arr, x, y);
end;

begin
end.
