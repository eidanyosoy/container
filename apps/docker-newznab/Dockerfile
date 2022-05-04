FROM ubuntu:latest 
ARG DEBIAN_FRONTEND=noninteractive

# Add Variables
ENV NNUSER="svnplus" \
    NNPASS="svnplu5"
    
# Install required packages
RUN apt update -yqq && apt upgrade -yqq && \
    apt-get install -yq \
       ssh screen tmux apache2 php php-fpm php-dev \
       php-pear php-gd php-mysql php-memcache php-curl php-json php-mbstring \
       unrar lame mediainfo subversion ffmpeg memcached nano
    
# Creating Newznab Folders from SVN
RUN mkdir /var/www/newznab/ \
          /var/www/newznab/htdocs \
          /var/www/newznab/logs && \
    svn export --no-auth-cache --force --username $NNUSER --password $NNPASS svn://svn.newznab.com/nn/branches/nnplus /var/www/newznab/ && \
    chmod 777 /var/www/newznab/www/lib/smarty/templates_c && \
    chmod 777 /var/www/newznab/www/covers/movies && \
    chmod 777 /var/www/newznab/www/covers/anime  && \
    chmod 777 /var/www/newznab/www/covers/music  && \
    chmod 777 /var/www/newznab/www/covers/tv && \
    chmod 777 /var/www/newznab/www  && \
    chmod 777 /var/www/newznab/www/install  && \
    chmod -R 777 /var/www/newznab/nzbfiles && \
    chmod -R 777 /var/www/newznab/www/covers
    
#Add Newznab Config File  
COPY ./apps/docker-newznab/config.php /var/www/newznab/www/config.php
RUN chmod 777 /var/www/newznab/www/config.php

# Configure Apache for Newznab site
COPY ./apps/docker-newznab/newznab.conf /etc/apache2/sites-available/newznab.conf

#Add newznab processing & Config script
COPY ./apps/docker-newznab/entrypoint.sh /entrypoint.sh
RUN chmod u+x /entrypoint.sh

EXPOSE 80

VOLUME /var/www/newznab/nzbfiles
VOLUME /var/www/newznab/www/covers

ENTRYPOINT ["/entrypoint.sh"]
