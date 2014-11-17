FROM opensuse:13.2
MAINTAINER Monoflash <monoflash@gmail.com>

RUN zypper --non-interactive --gpg-auto-import-keys ref
RUN zypper -n up

# add ownCloud repo + PHP extensions repo and install

RUN zypper ar -f -c http://download.opensuse.org/repositories/isv:/ownCloud:/community/openSUSE_13.2/isv:ownCloud:community.repo

RUN zypper ar -f -c http://download.opensuse.org/repositories/server:/php:/extensions/openSUSE_13.2/server:php:extensions.repo

RUN zypper -n --gpg-auto-import-keys ref

RUN zypper -n in owncloud glibc-locale

RUN zypper in -y apache2-mod_php5 php5 php5-fileinfo php5-fpm

# expose HTTP and HTTPS
EXPOSE 80
EXPOSE 443

RUN mv /etc/apache2/default-server.conf /etc/apache2/default-server.conf.old
RUN cat /etc/apache2/default-server.conf.old | sed --regexp-extended "s/^DocumentRoot (.*)$/DocumentRoot \"\/srv\/www\/htdocs\/owncloud\"/g" - > /etc/apache2/default-server.conf

# set owncloud permissions
RUN chown -R wwwrun:www /srv/www/htdocs/owncloud

# enable mod_php5
RUN a2enmod php5
RUN a2enmod ssl

#SSL
RUN cd /etc/apache2 \
&& openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out server.key \
&& chmod 600 server.key \
&& openssl req -new -batch -subj '/CN=ownCloud' -key server.key -out server.csr \
&& openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt

RUN cp /etc/apache2/server.crt /etc/apache2/ssl.crt/vhost-example.crt
RUN cp /etc/apache2/server.key /etc/apache2/ssl.key/vhost-example.key

RUN cat /etc/apache2/vhosts.d/vhost-ssl.template | sed --regexp-extended "s/DocumentRoot (.*)$/DocumentRoot \"\/srv\/www\/htdocs\/owncloud\"/g" - > /etc/apache2/conf.d/owncloud-ssl.conf

ADD processor/apache2.sh /etc/processor/apache2/run.sh
RUN chmod 770 /etc/processor
RUN chmod 775 /etc/processor/apache2/run.sh

# start Apache
CMD /etc/processor/apache2/run.sh
