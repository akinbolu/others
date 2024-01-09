SELECT CONCAT('#EXTINF:-1 tvg-id="', a.name, '" tvg-logo="', a.logo, '" group-title=\"', b.name, '",', a.name,
'\rhttp://|||server|||/play/live.php?mac=|||mac|||&stream=',a.id,'&extension=ts','\r') "#EXTM3U" FROM channels a, genres b
WHERE a.genre = b.id
and a.provider = b.provider
AND b.id NOT IN (SELECT id FROM blacklist WHERE provider = b.provider);