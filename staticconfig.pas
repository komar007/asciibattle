unit StaticConfig;

interface

const
	INITIAL_HP: array[0..9] of integer = (0, 10, 20, 30, 40, 50, 60, 70, 80, 100);
	INITIAL_HP_SPEED = 100;
	MIN_HP_SPEED = 5.0;
	CH: array [0..10] of char = (' ','.',',',':','&','%','#','$','@','O','G');
	FIELD_WIDTH = 0.2;
	FIELD_HEIGHT = 0.39;
	{ How much should the wind acceleration change per second }
	WIND_FLUCT = 0.3;
	{ More or less, every how many seconds should the wind change from
	  increasing to decreasing or vice versa }
	WIND_CHANGE_TIME = 2;
	SIGHT_LEN = 2;
	MAX_W = 5000;
	MAX_H = 5000;

implementation

begin
end.
