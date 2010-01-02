unit Lists;
interface
uses Types, Geometry;
type
	pRocketNode = ^RocketNode;

	RocketNode = record
		v: Rocket;
		next, prev: pRocketNode;
	end;

	RocketList = record
		head: pRocketNode;
		size: integer;
	end;

procedure new_list(var l: RocketList);
procedure new_node(var n: pRocketNode; v: Rocket);
procedure push_front(var list: RocketList; v: Rocket);
procedure destroy(var list: RocketList);
procedure remove(var list: RocketList; el: pRocketNode);
function find(var list: RocketList; var el: Rocket) : pRocketNode;
type
	pIntVectorNode = ^IntVectorNode;

	IntVectorNode = record
		v: IntVector;
		next, prev: pIntVectorNode;
	end;

	IntVectorList = record
		head: pIntVectorNode;
		size: integer;
	end;

procedure new_list(var l: IntVectorList);
procedure new_node(var n: pIntVectorNode; v: IntVector);
procedure push_front(var list: IntVectorList; v: IntVector);
procedure destroy(var list: IntVectorList);
procedure remove(var list: IntVectorList; el: pIntVectorNode);
function find(var list: IntVectorList; var el: IntVector) : pIntVectorNode;
implementation
procedure new_list(var l: RocketList);
begin
	l.head := nil;
	l.size := 0;
end;

procedure new_node(var n: pRocketNode; v: Rocket);
begin
	new(n);
	n^.v := v;
	n^.next := nil;
	n^.prev := nil;
end;

procedure push_front(var list: RocketList; v: Rocket);
var
	t: pRocketNode;
begin
	new_node(t, v);
	t^.next := list.head;
	if list.head <> nil then
		list.head^.prev := t;
	list.head := t;
	inc(list.size);
end;

procedure destroy(var list: RocketList);
var
	t: pRocketNode;
begin
	while list.head <> nil do begin
		t := list.head^.next;
		dispose(list.head);
		list.head := t;
	end;
	list.size := 0;
end;

procedure remove(var list: RocketList; el: pRocketNode);
begin
	if el = list.head then
		list.head := el^.next;

	if el^.next <> nil then
		el^.next^.prev := el^.prev;
	if el^.prev <> nil then
		el^.prev^.next := el^.next;
	dispose(el);
	dec(list.size);
end;

function find(var list: RocketList; var el: Rocket) : pRocketNode;
var
	cur, extra: pRocketNode;
begin
	new(extra);
	extra^.next := list.head;
	cur := extra;
	while cur^.next <> nil do
	begin
		if cur^.next^.v = el then
		begin
			find := cur^.next;
			exit;
		end
		else
			cur := cur^.next;
	end;
	dispose(extra);
	find := nil;
end;
procedure new_list(var l: IntVectorList);
begin
	l.head := nil;
	l.size := 0;
end;

procedure new_node(var n: pIntVectorNode; v: IntVector);
begin
	new(n);
	n^.v := v;
	n^.next := nil;
	n^.prev := nil;
end;

procedure push_front(var list: IntVectorList; v: IntVector);
var
	t: pIntVectorNode;
begin
	new_node(t, v);
	t^.next := list.head;
	if list.head <> nil then
		list.head^.prev := t;
	list.head := t;
	inc(list.size);
end;

procedure destroy(var list: IntVectorList);
var
	t: pIntVectorNode;
begin
	while list.head <> nil do begin
		t := list.head^.next;
		dispose(list.head);
		list.head := t;
	end;
	list.size := 0;
end;

procedure remove(var list: IntVectorList; el: pIntVectorNode);
begin
	if el = list.head then
		list.head := el^.next;

	if el^.next <> nil then
		el^.next^.prev := el^.prev;
	if el^.prev <> nil then
		el^.prev^.next := el^.next;
	dispose(el);
	dec(list.size);
end;

function find(var list: IntVectorList; var el: IntVector) : pIntVectorNode;
var
	cur, extra: pIntVectorNode;
begin
	new(extra);
	extra^.next := list.head;
	cur := extra;
	while cur^.next <> nil do
	begin
		if cur^.next^.v = el then
		begin
			find := cur^.next;
			exit;
		end
		else
			cur := cur^.next;
	end;
	dispose(extra);
	find := nil;
end;
end.
