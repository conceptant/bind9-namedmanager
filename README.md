This docker image implements BIND DNS server and provides web-interface for managing DNS zones, all in one image.

# Q&A

**What is BIND?**

BIND (Berkeley Internet Name Domain) is the most widely used DNS server on the modern Internet. Here is its official site: https://www.isc.org/downloads/bind/
You may also have heard about "named", a nameserver daemon which is a part of BIND software package.

**What is BIND9?**

BIND9 is a short name for BIND Version 9. Version 9 is the most secure and popular version of BIND.
It is open source and is actively maintained by ISC (Internet Systems Consortium).
You can download its source code here: https://www.isc.org/downloads/

**What is namedmanager?**

BIND itself does not provide any user-friendly interface for managing it, all configuration is done by editing files with rather sophisticated structure.
There are multiple implementations of such interface both opensource and commercial.
Jethro Carr (https://www.jethrocarr.com/) developed one of the simplest/best ones and still keeping eye on the project, unlike most other opensource web interface.
You can download the source code of namedmanager here: https://github.com/jethrocarr/namedmanager

**What is Conceptant, Inc.?**

Conceptant, Inc. is a business specializing on healthcare solutions. You can read about it here: http://conceptant.com/

**Why would I need this docker image?**

You may need this image if you need a quick solution that will implement an authoritative DNS server and manage it using a web interface instead of vi/ed/nano and other text editors.
This image will allow you to achieve this goal in minutes.

**Is this docker image production-ready?**

Only if you implement proper security measures.

The exact list depends on your specific configuration, but as a minumum set of security features you should:

- only allow public access port 53 (both TCP and UDP) in this docker container, nothing else. Port 53 is used by DNS. There are multiple ways to do this:
  - by consiguring security groups in AWS
  - by configuring a firewall running on the server itself (iptables or similar)
  - by using Web proxy ACLs
  - by configuring firewall in front of your DNS server
- only allow access to the namedmanager web interface from trusted computers:
  - by using use VPN to access the server
  - by using static IP for the server you use to access the DNS server and only allowing that IP to access the web interface (see the list above for your firewalling options)
  - only allow access to the web interface from the server itself and then use SSH tunneling to map port to your management computer (read more about this SSH feature here: https://www.ssh.com/ssh/tunneling/example)
- implement frequent backups and test restoring from the backup. In case of security breach you need to be able to quickly wipe out the whole system and restore it from from a clean state
- run volunerability scans on your DNS server
- use HTTPS with TLS 1.2 or above for connecting to the web interface (you will need to configure TLS termination on a proxy in front of the web interface)
- order penetration testing for your DNS server (it's expensive, but probably less expensive than being hacked)
- rebuilding this image with your own passwords and your own configuration
- delete the default namedmanager account and create a new one

**Having all-in-one DNS solution such as this image is awesome, isn't it?**

Well, not quite. In a real world production system you typically should not use docker like this. Instead, you should write a docker-compose file that would set up database, web server, name server, other services as separate containers.
You would probably also need to setup external volumes, edit the configuration etc. However, as a quick solution this image works pretty well, we're using it for our own test environments.

# Quick start

Here is the simplest form you can use to set up a temporary DNS server:
```
docker run -p 8090:8090 -p 53:53/tcp -p 53:53/udp conceptant/bind9-namedmanager
```
It will take a few moments to start and generate default configuration, and then you start configuring it using this URL: http://localhost:8090.
While the container performs the initialization it will output important information containing your RNDC key, default login and password.
You will need to write down this information so you can login into the web interface and manage the DNS server via rndc.


# Persisting the configuration

In order to persist the data, you will need to preserve the database between the container restarts as well as bind configuration files.
Here is how to keep these folders:
```
docker run -p 8090:8090 -p 53:53/tcp -p 53:53/udp -v <bind_config_dir>:/etc/bind -v <mysql_db_dir>:/var/lib/mysql conceptant/bind9-namedmanager
```
<bind_config_dir>, <mysql_db_dir> are the directories on docker host where the BIND configuration and Mariadb database will be persisted respectevely

Finally, you may want to add couple more handy configuration parameters:
```
docker run -d --restart unless-stopped -p 8090:8090 -p 53:53/tcp -p 53:53/udp -v <bind_config_dir>:/etc/bind -v <mysql_db_dir>:/var/lib/mysql -v <log_dir>:/var/log --name bind9 conceptant/bind9-namedmanager
```
-v <log_dir>:/var/log is something you may want to add so you can monitor the container logs from the host filesystem. You may also need this to preserve the logs for the audit purposes.
--restart unless-stopped will make the container restart after system reboot
--name will give it persistent name

# If you need to customize the docker file

```
git clone https://github.com/conceptant/bind9-namedmanager.git
```

Now make you customizations and build as usual:
```
docker build -t named .
```