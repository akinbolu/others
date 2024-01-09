SELECT
CONCAT('<?xml version="1.0" encoding="UTF-8"?>\r<!DOCTYPE tv SYSTEM "xmltv.dtd">\r<tv generator-info-name="Some tv generator">') "guide"
FROM dual
UNION
SELECT 
distinct CONCAT('  <channel id="',a.id,'">\r    <display-name lang="en">', b.name, '</display-name>\r    <icon src="',b.logo,'"/>\r  </channel>') "guide"
FROM guide a, channels b, genres c
WHERE a.id = b.id
AND b.genre = c.id
AND c.id NOT IN (SELECT id FROM blacklist WHERE provider = c.provider)
union
SELECT CONCAT(
'<programme start="',replace(replace(REPLACE(started,'-',''),':',''),' ',''),'" stop="', replace(replace(REPLACE(ended,'-',''),':',''),' ',''),'" channel="', a.id, '">\r    <title lang="en">', title, '</title>\r    <desc lang="en">', descr, '</desc>\r    <date>', DATE_FORMAT(NOW(),'%Y%m%d'), '</date>\r    <category lang="en"></category>\r</programme>') "guide"
FROM guide a, channels b, genres c
WHERE a.id = b.id
AND b.genre = c.id
AND c.id NOT IN (SELECT id FROM blacklist WHERE provider = c.provider)
UNION
SELECT '\r</tv>' FROM DUAL;