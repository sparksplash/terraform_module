#! /bin/bash
sudo su -

yum install -y httpd

amazon-linux-extras install php7.4
amazon-linux-extras enable php7.4

yum install -y php php-cli php-mysql 

wget https://ko.wordpress.org/latest-ko_KR.tar.gz
tar -xzf latest-ko_KR.tar.gz

cat > /var/www/html/health.html << end
<html><body><h1>healthy</h1></body></html>
end

cp -a wordpress/* /var/www/html/
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

chown apache.apache /var/www/html/*

sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php/g' /etc/httpd/conf/httpd.conf
systemctl start httpd
systemctl enable httpd
sed -i 's/database_name_here/wordpress/g' /var/www/html/wp-config.php
sed -i 's/username_here/wordpress/g' /var/www/html/wp-config.php
sed -i 's/password_here/It12345!/g' /var/www/html/wp-config.php
sed -i 's/localhost/terraform-20211018051608389500000001.cyztriv31e9o.ap-northeast-2.rds.amazonaws.com/g' /var/www/html/wp-config.php

sed -i "s/define( 'AUTH_KEY'/d" /var/www/html/wp-config.php
sed -i "s/define( 'SECURE_AUTH_KEY'/d" /var/www/html/wp-config.php
sed -i "s/define( 'LOGGED_IN_KEY'/d" /var/www/html/wp-config.php
sed -i "s/define( 'NONCE_KEY'/d" /var/www/html/wp-config.php
sed -i "s/define( 'AUTH_SALT'/d" /var/www/html/wp-config.php
sed -i "s/define( 'SECURE_AUTH_SALT'/d" /var/www/html/wp-config.php
sed -i "s/define( 'LOGGED_IN_SALT'/d" /var/www/html/wp-config.php
sed -i "s/define( 'NONCE_SALT'/d" /var/www/html/wp-config.php



sed -i '51 i\define("AUTH_KEY",         "3{t^k2=S@d0-qwq)YIlQIswF$slz{rrduN%1 Le06yhg:-f.v%%g|e8;lb#%U8-F");' /var/www/html/wp-config.php
sed -i '52 i\define("SECURE_AUTH_KEY",  "^`,v|v)+8oQ`%){b4f2t$:%;yLE[y]K,0wlqQt5mUKvds:v^6GA$%SCqX3P>f `&");' /var/www/html/wp-config.php
sed -i '53 i\define("LOGGED_IN_KEY",    "oh9-seEDDS`Mo-g-{~/C*^v|GX4!_|BU^F,bfKfiIBe IY.RH+,MmaQ{@PwI,3y+");' /var/www/html/wp-config.php
sed -i '54 i\define("NONCE_KEY",        "4-##^p.hqXBw6.FdP-{s-2eY{Ra~[ta[L-?B-/p<uzvb0 za_P]@3Gp`5,pw,l]T");' /var/www/html/wp-config.php
sed -i '55 i\define("AUTH_SALT",        "FC=xS:x+/?M])4Kjt~m*7ys[J92CwQ&Sv9SP[7_zm~P|pXE%q:CD#NqjULl5D?@J");' /var/www/html/wp-config.php
sed -i '56 i\define("SECURE_AUTH_SALT", "?`(ATb,+(X|P/G(O`/bweK+}iX9^1v6@Q2g:zm30#umb[$X?9kne9rK~c #(N=5~");' /var/www/html/wp-config.php
sed -i '57 i\define("LOGGED_IN_SALT",   ";R[pT6C<eiZ}zaH-&=)OW6bnCn0m&6h@gMg8gR&ju25Z,+h?|[C)1>8rb?E>V1+S");' /var/www/html/wp-config.php
sed -i '58 i\define("NONCE_SALT",       "a/ h~L(vW>cx-2kP<qV+&$62`g45aAW<5MHkk!bbgX@49vh(6s|uq!M$<_Y{c^%{");' /var/www/html/wp-config.php