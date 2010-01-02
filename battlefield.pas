unit BattleField;

interface

type
	BFieldElement = record
		hp: double;
		current_hp: double;
		previous_hp: double;
		hp_speed: double;
	end;

	BField = record
		width, height: integer;
		arr: array of array of BFieldElement;
	end;

	pBField = ^BField;
	pBFieldElement = ^BFieldElement;

procedure new_bfield(var field: BField; x, y: integer);


implementation


procedure new_bfield(var field: BField; x, y: integer);
begin
	field.width := x;
	field.height := y;
	setlength(field.arr, x, y);
end;

begin
end.
