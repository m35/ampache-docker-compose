# Ampache Docker with separate containers

There are other Ampache Docker containers available.
This one tries to follow the Docker best practice of a single process per container.

# Quick start

Put your music in `/media/music`.

1. In the directory of this project, run
```
docker-compose up -d
```

2. The MySQL root password is randomly generated and can be found in the Docker logs.

To quickly locate it, run this
```
docker logs ampache-mysql 2>&1 | grep "GENERATED ROOT PASSWORD"
```

3. Browse to the installed Ampache homepage (e.g. `http://localhost`).

4. Begin the Ampache installation process.
5. For MySQL Hostname use `ampache-mysql`.
6. For MySQL Administrative Password use the password from above.
7. Create database
8. Create tables
9. Create user

10. Add a music catalog at path `/music` (which maps to your local directory `/media/music`).

## Configuration

Here are the settings you may want to change to meet your needs, and their default values.

* Port for the Ampache web server (default 80)
* Port for phpmyadmin (default 8080)
* Directory to put your music (default `/media/music`)

These settings can be changed in `docker-compose.yml`.
In the future, these could be made as parameters or environment variables (maybe using a Docker `.env` file).

The default url path to Ampache is `/`. I would like to make that configurable, but existing webservers make that painful.

There are additional settings used by the MySQL service
that can be found under 'Environment Variables' on the MySQL Docker page https://hub.Docker.com/_/mysql/.

There are also settings you may want to manually change in the Ampache config/ampache.cfg.php

# How it was all put together

For starters, I do want to thank those who have put together other Docker images for Ampache. This work couldn't have been done without their reference.


## The web server

[Lighttpd](https://www.lighttpd.net/) was used as the web server. My subjective reasoning:

* Easier to wrap my head around than Apache
* Easier to change the the root url path
* Easier to setup ssl

I'm sure seasoned Apache users wouldn't have these issues.

There is no pre-made Lighttpd Docker images, but the setup script is is ridiculously simple since Lighttpd is a package in the Alpine Linux repo.
At least it *was* simple until I wanted the cutting edge v1.4.50 which has enhanced mod_rewrite features.
So now it builds Lighttpd from scratch. It helped having the existing Alpine Linux packaging process as a reference.
Obviously this build mess can be removed when a newer package is available in the Alpine Linux repo.
(at this point using Apache might sound like a much better idea)

For ssl, again it looked hard to setup on Apache. So if I were to use Apache, I was going to add another "reverse-proxy" container to take care of the ssl part. This would have still introduced another image along with the already large Apache image. So the number of containers remained the same by combing that with Lighttpd (but maybe it should still be moved into a separate container anyway).

### Challenges

Probably the biggest hurdle of using Lighttpd was translating all the Apache permissions and mod_rewrite rules into Lighttpd style. If they are ever changed in Ampache,they will need to be updated.

Lighttpd requires the IP address of the php FPM server, and cannot use the host name. Within the Docker network, the service name is also its host name. Docker allows you to hard-code the IP address of a container, but my subnet and gateway knowledge is weak. So instead I added an extra script that will resolve the ip address and hand that to Lighttpd.

The www-data group and www-data users in the Alpine world and Debian world use different UID and GID. On top of that, Alpine's UID and GID are mapped to the xfs:xfs user:group. Since Lighttpd is under Alpine and PHP is under Debian, permissions between the shared server files got kind of confusing. We want PHP on Debian do ensure the many apt dependencies are available. It seems a common 'fix' is to just delete the xfs user and group and take over their UID:GID.

## PHP

Like the Apache install, Lighttpd needs to execute php scripts. The so called [php-fpm](https://hub.Docker.com/_/php/0) image takes care of executing those scripts (FPM stands for "FastCGI Process Manager").
On top of that image, Ampache is installed along with its many dependencies. This separate container is where all the php scripts are executed along with all media processing.

It is common to combine the Apache and php pieces together into its own larger image (which can also be found on the [php Docker page](https://hub.Docker.com/_/php/0)).
It was nice being able to split up the work into two smaller images, each with their own concerns.

Even when trying to keep a single process per container, it appears wise to setup a cron job to tell Amache to re-sync its music library periodically. I couldn't find any way around it so injected my own script into the PHP image to start cron just before the container starts up. 

## MySQL

Regardless of how the web server and php were put together, MySQL should definitely be in its own container. The default image is all we need.

## phpmyadmin

Because why not.
