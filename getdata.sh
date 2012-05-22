#!/bin/bash
#Get shortcode data for creation/updating of product on the web site
#Vine server has the shortcodes - this just gives us a .csv file

#I keep a long list of my full sql export routine commented out here,
# so I don't have to work it out each time. It's rare that I run
# a full update of our database (more than 100K products = long time)

#WHERE `shortcode` like "salt"
#or `shortcode` REGEXP "^WL PP[0-9]"

#This get's the data from our internal server. -p means it asks for a password
 
mysql -h vine.rkbb.co.uk -u yourusername -p -e 'SELECT `shortcode`,`sellingdescription`,`retail price ex vat`
FROM `tallyman`.`ShortCodes`
WHERE `shortcode` like "salt"
or `shortcode` like "myproduct"
' > webdata.tab
#gets data from mysql, format is tab separated
perl -lpe 's/"/""/g; s/^|$/"/g; s/\t/","/g' < webdata.tab > webdata.csv
#converts tab separated to comma separated
iconv -f ISO-8859-1 -t utf-8 webdata.csv > webdata-utf8.csv
#converts csv into UTF8 encoding

#get rid of the two temporary files (.tab and .csv)
rm webdata.tab
rm webdata.csv

echo "Data is ready to use, file: webdata-utf8.csv"

#Tell me, how many results were there?
#This is useful because if I made a mistake in my sql I have a 
#chance to realise now instead of at the end of my import.
echo "How many results did you expect? Because you got:"
sed '/^\s*$/d' webdata-utf8.csv | wc -l
exit
