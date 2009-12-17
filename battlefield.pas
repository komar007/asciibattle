unit BattleField;

interface

type
	BFieldElement = record
		hp: integer;
	end;

	BField = record
		width, height: integer;
		arr: array of array of BFieldElement;
	end;

procedure bfield_init(var field: BField; x, y: integer);


implementation


procedure bfield_init(var field: BField; x, y: integer);
begin
	field.width := x;
	field.height := y;
	setlength(field.arr, x, y);
end;

begin
end.
