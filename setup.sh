#!/bin/bash

echo "### パッケージのインストール開始 ###"
yum -y install httpd php postgresql postgresql-server php-mbstring php-pgsql php-gd

echo "### Pythonに必要なパッケージをインストール開始 ###"
yum -y install wget gcc gcc-c++ zlib-devel openssl-devel readline-devel ncurses-devel sqlite-devel expat-devel bzip2-devel tcl-devel tk-devel gdbm-devel libbsd-devel

echo "### C++に必要なパッケージをインストール開始 ###"
yum -y install devtoolset-2-gcc devtoolset-2-binutils devtoolset-2-gcc-c++ devtoolset-2-gcc-gfortran

echo "### Python3.3.3をダウンロード ###"
wget http://www.python.org/ftp/python/3.3.3/Python-3.3.3.tgz
mv -f Python-3.3.3.tgz /usr/local/src/
tar zxvf /usr/local/src/Python-3.3.3.tgz
mv -f Python-3.3.3 /usr/local/src/
/usr/local/src/Python-3.3.3/configure --prefix=/usr/local/python-3.3
make
make install
export PATH=/usr/local/python-3.3/bin:$PATH
ln -s /usr/local/python-3.3/bin/python3.3 /usr/local/bin/python-test

echo "### GCC4.8をインストール ###"
cd  /etc/yum.repos.d/
wget http://people.centos.org/tru/devtools-2/devtools-2.repo
scl enable devtoolset-2 bash

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

echo "### Pythonにテスト用コード作成 ###"
echo "print(\"Hello World\")"		> /var/www/html/check.py

echo "### C++にテスト用コード作成 ###"
echo "#include <iostream>"                      >       /var/www/html/check.cc
echo "using namespace std;"                     >>      /var/www/html/check.cc
echo ""                                         >>      /var/www/html/check.cc
echo "int main(){"                              >>      /var/www/html/check.cc
echo "cout << \"Hello World! C++\" << endl;"    >>      /var/www/html/check.cc
echo "return 0;"                                >>      /var/www/html/check.cc
echo "}"                                        >>      /var/www/html/check.cc

echo ### パッケージを更新開始 ###
yum -y update
echo ### パッケージを更新終了 ###


echo "### 接続テスト結果 ###"
php /var/www/html/check_db.php

echo "### Python3.3の動作検証 ###"
python3.3 /var/www/html/check.py

echo "### C++の動作検証ファイルをコンパイル ###"
cd/var/www/html
g++ check.cc -o check_c++
echo "### C++の動作検証ファイルを実行 ###"
cd/var/www/html
./check_c++