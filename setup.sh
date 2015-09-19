#!/bin/bash

echo "### パッケージのインストール開始 ###"
yum -y install httpd php postgresql postgresql-server php-mbstring php-pgsql php-gd


echo "### httpdを起動 ###"
chkconfig httpd on
service httpd start


echo "### Postgresqlを初期化 ###"
service postgresql initdb


echo "### postgresql.confの書き換え開始 ###"
sed -i -e "59s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf
sed -i -e "334s/#log_line_prefix = ''/log_line_prefix = '%t %u %d'/"    /var/lib/pgsql/data/postgresql.conf


echo "### pg_hba.confの書き換え開始 ###"
sed -i -e "70,74s/ident/trust/"	/var/lib/pgsql/data/pg_hba.conf


echo "### postgresqlの起動開始 ###"
chkconfig postgresql on
service postgresql start


echo "### Postgresqlの設定開始 ###"
sudo -u postgres psql -c "alter user postgres with password 'test1192'"
sudo -u postgres createuser -s apache
sudo -u postgres createdb testdb


echo "### ドキュメント・ルートにテスト用コード作成 ###"
echo "<?php"                                                                    >       /var/www/html/check_db.php
echo "if (!pg_connect(\"dbname=testdb user=postgres password=test1192\")) {"    >>      /var/www/html/check_db.php
echo "print(\"CONNECT ERROR!!\n\");"                                            >>      /var/www/html/check_db.php
echo "} else {"                                                                 >>      /var/www/html/check_db.php
echo "print(\"CONNECT OK\n\");"                                                 >>      /var/www/html/check_db.php
echo "}"                                                                        >>      /var/www/html/check_db.php
echo "?>"                                                                       >>      /var/www/html/check_db.php


echo ### パッケージを更新開始 ###
yum -y update
echo ### パッケージを更新終了 ###


echo "### 接続テスト結果 ###"
php /var/www/html/check_db.php