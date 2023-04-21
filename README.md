Proxy service powered by Squid + Privoxy + Tor
===============================================

A secure proxy(HTTP) server powered by Docker compose, it includes Squid, Privoxy and Tor.

Three containers,

* Squid as the HTTP proxy, the configuration does NOT have any disk cache
* Privoxy used as proxy bridge to Tor
* Tor

# Quick start

0. Clone this repository

1. Copy the _homeproxy.env_ to the destination folder(e.g. /homeproxy), change the filename to homeproxy.prod

2. Update the content of the homeproxy.prod(dev) file 

```
SERVICE_DESTINATION=/homeproxy
```

3.  Run _sync_deployment.sh_

```
# ./sync_deployment.sh -c /homeproxy/homeproxy.prod
```

4. Setup the password file in the destination folder(e.g. /homeproxy/etc/squid/passwords)

```
# ./htpasswd.sh username password > /homeproxy/etc/squid/passwords
```

5. Start the proxy service

```
# /homeproxy/bin/start.sh
```

Or start as daemon, 

```
# /homeproxy/bin/start.daemon.sh
```

The proxy service is listen at port 3128 and you might setup the port forward in the load balancer or router to public the proxy service.

Enjoy it.
