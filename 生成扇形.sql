--生成扇形
--lng 中心经度
--lat 中心纬度
--angle 方位角
--covertype 室分（这里是项目中用到，不必须），室内为圆，室外为扇形
CREATE OR REPLACE FUNCTION createSector ( lng NUMERIC, lat NUMERIC, angle NUMERIC, covertype VARCHAR ) RETURNS VARCHAR AS $wkt$ DECLARE
sector_radius NUMERIC = 0.1;--扇形半径
circle_radius NUMERIC = 0.05;--圆半径
sector_angle NUMERIC = 50;--扇形角度
sector_pointnum INTEGER = 50;--扇形点的数量
circle_pointnum INTEGER = 360;--圆的点数量
rad NUMERIC = pi() / 180;
rdloncos NUMERIC;
sector_perpointangle NUMERIC;
circle_perpointangle NUMERIC;
_index INTEGER = 50;
_cindex INTEGER = 360;
current_angle NUMERIC = 0;
wkt VARCHAR;
BEGIN
	IF
		( lng IS NULL ) THEN
			wkt = '';
		RETURN wkt;
		
	END IF;
	IF
		( lat IS NULL ) THEN
			wkt = '';
		RETURN wkt;
		
	END IF;
	IF
		( angle IS NULL ) THEN
			angle = 0;
		
	END IF;
	IF
		( covertype = '室内' ) THEN
			circle_perpointangle = 360 / circle_pointnum;
		rdloncos = 111 * cos( lat * rad );
		wkt = 'POLYGON((' || lng || ' ' || lat || ',';
		while
		_cindex >- 1
		loop
		current_angle = circle_perpointangle * _cindex;
		IF
			( current_angle = 360 ) THEN
				current_angle = 0;
			
		END IF;
		wkt = wkt || ( lng + ( circle_radius * sin( current_angle * rad )) / rdloncos ) || ' ' || ( lat + circle_radius * cos( current_angle * rad ) / 111 ) || ',';
		_cindex = _cindex - 1;
		
	END loop;
wkt = wkt || lng || ' ' || lat || '))';
ELSE sector_perpointangle = sector_angle / sector_pointnum;
rdloncos = 111 * cos( lat * rad );
wkt = 'POLYGON((' || lng || ' ' || lat || ',';
while
_index >- 1
loop
current_angle = angle - sector_angle / 2+sector_perpointangle * _index;
IF
	( current_angle > 360 ) THEN
		current_angle = current_angle - 360;
	
END IF;
wkt = wkt || ( lng + ( sector_radius * sin( current_angle * rad )) / rdloncos ) || ' ' || ( lat + sector_radius * cos( current_angle * rad ) / 111 ) || ',';
_index = _index - 1;

END loop;
wkt = wkt || lng || ' ' || lat || '))';

END IF;
RETURN wkt;

END;  
$wkt$ LANGUAGE plpgsql;