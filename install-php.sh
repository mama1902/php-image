#!/bin/bash

userName="www"
userGroup="www"

version=$1;

if [ -z "$version" ]; then
    version="7.4.21"
fi

installDir="$2"

if [ -z "$installDir" ]; then
    installDir="/usr/local/php"
fi

fileName="php-$version.tar.bz2"

sudo apt-get update -y

sudo apt-get upgrade -y

sudo apt-get install libxml2-dev build-essential openssl libssl-dev curl  \
  libcurl4-gnutls-dev libjpeg-dev libpng-dev libmcrypt-dev libreadline6-dev libfreetype6-dev \
  libzip-dev libsqlite3-dev libtool pkg-config libwebp-dev -y

if [ ! -f /usr/lib/libssl.so ]; then
   if [ -f /usr/lib/x86_64-linux-gnu/libssl.so ]; then
      ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/lib/libssl.so
   else
      echo "libssl.so not found, execute the command 'find / -name libssl.so' to find and soft link" && exit 1
   fi
fi

if [ ! -d /usr/include/curl ]; then
   if [ -d /usr/include/x86_64-linux-gnu/curl ]; then
      ln -s /usr/include/x86_64-linux-gnu/curl /usr/include/curl
   else
      echo "/usr/include/curl and /usr/include/x86_64-linux-gnu/curl non-existent" && exit 1
   fi
fi

if [ -n $(command -v onig-config) ]; then
  echo "install oniguruma:6.9.4 doing..."

  #wget "https://github.com/kkos/oniguruma/archive/v6.9.4.tar.gz" -O "oniguruma-6.9.4.tar.gz"

  #if ! wget -c -O "oniguruma-6.9.4.tar.gz" "https://github.com/kkos/oniguruma/archive/v6.9.4.tar.gz"; then echo "wget download oniguruma fail"; exit 1; fi
  cd /usr/local/
  if [ ! -f "oniguruma-6.9.4.tar.gz" ]; then echo "oniguruma-6.9.4.tar.gz not found"; exit 1; fi

  if ! tar -xvf "oniguruma-6.9.4.tar.gz"; then echo "oniguruma-6.9.4.tar.gz decompression fail"; exit 1; fi

  cd ./oniguruma-6.9.4/  && sudo ./autogen.sh &&  sudo ./configure && sudo make -j4 && sudo make install && cd ../

  if [ $? -ne 0 ]; then
     echo "install oniguruma fail" && exit 1
  fi

  echo "install oniguruma:6.9.4 success"
fi

#if ! wget -c -O "$fileName" "https://www.php.net/distributions/$fileName"; then echo "wget download php-$version fail"; exit 1; fi
cd /usr/local/
if [ ! -f "$fileName" ]; then echo "$fileName not found"; exit 1; fi

if ! tar -xvf "$fileName"; then echo "decompression fail"; exit 1; fi

cd "./php-$version/" && ./configure --prefix="$installDir" --with-config-file-path="$installDir/etc" --enable-fpm --with-fpm-user="$userName" --with-fpm-group="$userGroup" --with-mysqli --with-pdo-mysql --with-iconv-dir  --with-jpeg --with-webp  --with-zlib --with-libxml=/usr --enable-xml --enable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --enable-ftp --with-freetype --enable-gd --with-openssl --with-mhash --enable-intl --enable-pcntl --enable-sockets --with-xmlrpc --with-zip --enable-soap --without-pear --with-gettext --enable-fileinfo --enable-maintainer-zts && sudo make -j4 && sudo make install

if [ $? -ne 0 ]; then
   echo "install php:$version fail" && exit 1
fi

if [ ! -d "$installDir" ]; then
  echo "install fail" && exit 1
fi

#wget -nc -q http://pecl.php.net/get/redis-6.0.2.tgz
cd /usr/local/
tar xvf redis-6.0.2.tgz
cd redis-6.0.2
"$installDir"/bin/phpize
./configure  --with-php-config="$installDir"/bin/php-config
make -j 4 && make install
sudo cp /app/www/php.ini  "$installDir/etc/php.ini"
sed -i '$a extension=redis.so' "$installDir"/etc/php.ini
sudo apt-get install -y libsodium-dev
cd /usr/local/
tar xvf libsodium-2.0.23.tgz
cd libsodium-2.0.23
"$installDir"/bin/phpize
./configure  --with-php-config="$installDir"/bin/php-config
make -j 4 && make install
sed -i '$a extension=sodium.so' "$installDir"/etc/php.ini


ls -l "$installDir"/etc/

sudo cp "$installDir/etc/php-fpm.conf.default"  "$installDir/etc/php-fpm.conf"

sudo cp "$installDir/etc/php-fpm.d/www.conf.default" "$installDir/etc/php-fpm.d/www.conf"

sudo groupadd "$userGroup" >/dev/null 2>&1

sudo useradd -g "$userGroup" "$userName" >/dev/null 2>&1

sudo ln -s "$installDir"/bin/* /usr/bin

sudo ln -s "$installDir"/sbin/* /usr/sbin

sudo php-fpm
