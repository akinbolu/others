cd ~/others
rm -f ./iptv/*.temp ./iptv/*.gz ./iptv/guide ./iptv/genres ./iptv/channels;

###########################################################################################################################
# EXTRACT TOP PROVIDERS
###########################################################################################################################

mariadb -N -u root -pP@ssw0rd livetv -e "select mac, validity, owner from providers WHERE provider = 'POWERIP' and OWNER IS NOT null
UNION (select mac, validity, owner from providers WHERE provider = 'POWERIP' and OWNER IS null ORDER BY validity DESC LIMIT 5)" > ./iptv/powerip.lst;

mariadb -N -u root -pP@ssw0rd livetv -e "select mac, validity, owner from providers WHERE provider = 'PHOENIX' and OWNER IS NOT null
UNION (select mac, validity, owner from providers WHERE provider = 'PHOENIX' and OWNER IS null ORDER BY validity DESC LIMIT 5)" > ./iptv/phoenix.lst;

mariadb -N -u root -pP@ssw0rd livetv -e "select mac, validity, owner from providers WHERE provider = 'ULTRABOX' and OWNER IS NOT null
UNION (select mac, validity, owner from providers WHERE provider = 'ULTRABOX' and OWNER IS null ORDER BY validity DESC LIMIT 5)" > ./iptv/ultrabox.lst;

###########################################################################################################################
# UPDATE PROVIDERS INTO DATABASE FROM LATEST SOURCE FILES
###########################################################################################################################

mariadb -N -u root -pP@ssw0rd livetv -e 'select * from sources' > ./iptv/providers_list.temp;
while IFS= read -r line; do
	provider_url=`echo ${line} | awk '{print $1}'`
	provider_name=`echo ${line} | awk '{print $2}'`
	provider_file=`echo ${line} | awk '{print $3}'`
	echo 'insert IGNORE into providers (mac,url,validity,provider) values '  > ./iptv/sql.temp;

	perl -C -lne '
	print "(\"" . $1 . "\",\"|||url|||\",STR_TO_DATE(\"" . $2 . "\", \"%M %d, %Y\"),\"|||provider|||\"),"
	while /(\S+:\S+:\S+:\S+:\S+:\S+).*?\s\[(\S+\s\d+,\s\d+)/ig
	' $provider_file >> ./iptv/sql.temp;

	sed -i "s/|||provider|||/${provider_name}/g" ./iptv/sql.temp;
	sed -i "s#|||url|||#${provider_url}#g" ./iptv/sql.temp;
	sed -z 's/\(.*\),/\1/' ./iptv/sql.temp > ./iptv/valid_providers.temp;
	echo 'ON DUPLICATE KEY UPDATE validity = values(validity), channels = 999' >> ./iptv/valid_providers.temp;
	mysql -u root -pP@ssw0rd livetv < ./iptv/valid_providers.temp  >> /dev/null 2>&1;
	sleep 2;
done < ./iptv/providers_list.temp

###########################################################################################################################
# RUN INIT SCRIPTS
###########################################################################################################################

mariadb -N -u root -pP@ssw0rd livetv -e 'call init_script' >> /dev/null 2>&1;
sleep 2;

###########################################################################################################################
# GET CURRENT LIST AND DETAILS OF SUBSCRIBERS
###########################################################################################################################

mariadb -N -u root -pP@ssw0rd livetv -e 'SELECT a.mac, b.provider_url, b.git_user, b.git_token, b.git_repo, a.provider, lower(a.name) from subscribers a, sources b
WHERE a.provider = b.provider_name and a.category = 1' > ./iptv/subscribers_list.temp;

###########################################################################################################################
# RUN STANDARD PROCESSES FOR SUBSCRIBERS
###########################################################################################################################

while IFS= read -r line; do
	mac=`echo ${line} | awk '{print $1}'`
	server=`echo ${line} | awk '{print $2}'`
	git_user=`echo ${line} | awk '{print $3}'`
	git_token=`echo ${line} | awk '{print $4}'`
	git_repo=`echo ${line} | awk '{print $5}'`
	provider=`echo ${line} | awk '{print $6}'`
	subscriber_name=`echo ${line} | awk '{print $7}'`

	cp ./iptv/channels_extract_template.sql ./iptv/channels_extract.temp
	sed -i "s/|||mac|||/${mac}/g" ./iptv/channels_extract.temp
	sed -i "s/|||server|||/${server}/g" ./iptv/channels_extract.temp
	sed -i "s/|||provider|||/${provider}/g" ./iptv/channels_extract.temp

	cp ./iptv/guide_extract_template.sql ./iptv/guide_extract.temp
	sed -i "s/|||provider|||/${provider}/g" ./iptv/guide_extract.temp

	###########################################################################################################################
	# DOWNLOAD CHANNELS, PLAYLISTS AND GENRES
	###########################################################################################################################
	
	echo 1 > ./iptv/test.temp;
	while [ -s ./iptv/test.temp ]; do
		curl -X GET "http://$server/server/load.php?JsHttpRequest=1-xml&action=get_all_channels&force_ch_link_check=&type=itv" -H "Cookie: mac=$mac; stb_lang=en; timezone=GMT" -H "Host: $server" -H 'Accept-Encoding: gzip, deflate' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:57.0) Gecko/20100101 Firefox/57.0' -H 'X-User-Agent: Model: MAG254; Link: Ethernet' -o ./iptv/channels.gz;
		gzip -t ./iptv/channels.gz 2> ./iptv/test.temp
		sleep 2
	done

	echo 1 > ./iptv/test.temp;
	while [ -s ./iptv/test.temp ]; do
		curl -X GET "http://$server/server/load.php?JsHttpRequest=1-xml&action=get_genres&type=itv" -H "Cookie: mac=$mac; stb_lang=en; timezone=GMT" -H "Host: $server" -H 'Accept-Encoding: gzip, deflate' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:57.0) Gecko/20100101 Firefox/57.0' -H 'X-User-Agent: Model: MAG254; Link: Ethernet' -o ./iptv/genres.gz;
		gzip -t ./iptv/genres.gz 2> ./iptv/test.temp
		sleep 2
	done

	echo 1 > ./iptv/test.temp;
	while [ -s ./iptv/test.temp ]; do
		curl -X GET "http://$server/server/load.php?JsHttpRequest=1-xml&action=get_epg_info&type=itv" -H "Cookie: mac=$mac; stb_lang=en; timezone=GMT" -H "Host: $server" -H 'Accept-Encoding: gzip, deflate' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:57.0) Gecko/20100101 Firefox/57.0' -H 'X-User-Agent: Model: MAG254; Link: Ethernet' -o ./iptv/guide.gz;
		gzip -t ./iptv/guide.gz 2> ./iptv/test.temp
		sleep 2
	done

	gzip -df ./iptv/genres.gz ./iptv/channels.gz ./iptv/guide.gz;

	###########################################################################################################################
	# UPDATE CHANNELS
	###########################################################################################################################

	echo 'truncate table channels; insert IGNORE into channels values '  > ./iptv/sql.temp;

	perl -C -lne '
	print "(" .$1 . ",\"" . $2 . "\"," . $3 . ",\"" . $4 . "\",\"" . $5 . "\",\"|||provider|||\"),"
	while /,{"id":"(\d+).*?"name":"([^#].+?)".*?"tv_genre_id":"(\d{0,}).*?"xmltv_id":"(\S{0,}?)".*?"logo":"(\S{0,}?)"/ig
	' ./iptv/channels >> ./iptv/sql.temp;

	sed -z 's/\(.*\),/\1/' ./iptv/sql.temp > ./iptv/channels.temp;
	sed -i "s/|||provider|||/${provider}/g" ./iptv/channels.temp;
	sed -i 's|\\/|/|g' ./iptv/channels.temp;
	sed -i 's|\\||g' ./iptv/channels.temp;
	sed -i "s|'||g" ./iptv/channels.temp;
	sed -i "s|&| and |g" ./iptv/channels.temp;

	###########################################################################################################################
	# UPDATE GENRES
	###########################################################################################################################

	echo 'truncate table genres; insert IGNORE into genres values '  > ./iptv/sql.temp;

	perl -C -lne '
	print "(" .$1 . ",\"" . $2 . "\",\"|||provider|||\"),"
	while /,{"id":"(\d+).*?"title":"([^#].+?)"/ig
	' ./iptv/genres >> ./iptv/sql.temp;

	sed -z 's/\(.*\),/\1/' ./iptv/sql.temp > ./iptv/genres.temp;
	sed -i "s/|||provider|||/${provider}/g" ./iptv/genres.temp;
	sed -i 's|\\/|/|g' ./iptv/genres.temp;
	sed -i 's|\\||g' ./iptv/genres.temp;
	sed -i "s|'||g" ./iptv/genres.temp;
	sed -i "s|&| and |g" ./iptv/genres.temp;

	###########################################################################################################################
	# UPDATE GUIDE
	###########################################################################################################################

	echo 'truncate table guide; insert IGNORE into guide values '  > ./iptv/sql.temp;

	perl -C -lne '
	print "(" . $1 . ",|||" . $2 . "|||,|||" . $3 . "|||,|||" . $4 . "|||,|||" . $5 . "|||,|||" . $6 . "|||,||||||provider||||||),"
	while /,"ch_id":"(\d+).*?"time":"(.+?)".*?"time_to":"(.+?)".*?"name":"([\S|\s]{0,}?)".*?"descr":"([\S|\s]{0,}?)",.*?"on_date":".*?(\d{2}.\d{2}.\d{4}?)"/ig
	' ./iptv/guide >> ./iptv/sql.temp;

	sed -i 's|"||g' ./iptv/sql.temp;
	sed -i "s|'||g" ./iptv/sql.temp;
	sed -i 's|\\||g' ./iptv/sql.temp;
	sed -i 's|/||g' ./iptv/sql.temp;
	sed -i "s|<||g" ./iptv/sql.temp;
	sed -i "s|>||g" ./iptv/sql.temp;
	sed -i "s|&| and |g" ./iptv/sql.temp;
	sed -i "s/|||provider|||/${provider}/g" ./iptv/sql.temp;
	sed -i 's/|||/"/g' ./iptv/sql.temp;
	sed -z 's/\(.*\),/\1/' ./iptv/sql.temp > ./iptv/guide.temp;

	###########################################################################################################################
	# INSERT CHANNELS, GENRES AND GUIDE INTO DATABASE
	###########################################################################################################################

	mariadb -u root -pP@ssw0rd livetv < ./iptv/channels.temp  >> /dev/null 2>&1;
	sleep 2;
	mariadb -u root -pP@ssw0rd livetv < ./iptv/genres.temp  >> /dev/null 2>&1;
	sleep 2;
	mariadb -u root -pP@ssw0rd livetv < ./iptv/guide.temp  >> /dev/null 2>&1;
	sleep 2;
	
	###########################################################################################################################
	# EXTRACT PLAYLIST AND GUIDE DATABASE; REMOVE TEMP FILES
	###########################################################################################################################
	
	mariadb -u root -pP@ssw0rd livetv < ./iptv/channels_extract.temp > ./iptv/playlist_${subscriber_name}.m3u;
	sleep 2;
	mariadb -N -u root -pP@ssw0rd livetv < ./iptv/guide_extract.temp > ./iptv/guide_${subscriber_name}.xml;

	##########################################################################################################################

	rm -f ./iptv/*.temp ./iptv/*.gz ./iptv/guide ./iptv/genres ./iptv/channels;

	##########################################################################################################################

	playlist_lines=$(wc -l < ./iptv/playlist_${subscriber_name}.m3u)
	guide_lines=$(wc -l < ./iptv/guide_${subscriber_name}.xml)
	if [[ "$playlist_lines" -le 10 && $guide_lines -le 10 ]]
	then
		exit;
	fi

done < ./iptv/subscribers_list.temp

##########################################################################################################################
# COMMIT CHANGES TO GIT
##########################################################################################################################

rm -rf .git 
git init 
git checkout --orphan newBranch
git add .
git commit -am "Playlist update"
git branch -D main
git branch -m main
git push -f https://${git_user}:${git_token}@${git_repo} main
