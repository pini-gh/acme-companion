This fork of [docker-letsencrypt-nginx-proxy-companion](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion) uses [acme.sh](https://github.com/acmesh-official/acme.sh) as Let's Encrypt client (instead of simp_le) and brings support for:
* DNS mode challenge
* Wilcard domain certificates

It is based on [initial work by @buchdag](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion/issues/510).

**letsencrypt-nginx-proxy-companion** is a lightweight companion container for [**nginx-proxy**](https://github.com/jwilder/nginx-proxy).

It handles the automated creation, renewal and use of Let's Encrypt certificates for proxyed Docker containers.

Please note that **letsencrypt-nginx-proxy-companion** no longer supports ACME v1 endpoints. The last tagged version that supports ACME v1 is [v1.11](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion/releases/tag/v1.11.2)

### Features:
* Automated creation/renewal of Let's Encrypt (or other ACME CAs) certificates using [**simp_le**](https://github.com/zenhack/simp_le).
* Let's Encrypt / ACME domain validation through `http-01` challenge only.
* Automated update and reload of nginx config on certificate creation/renewal.
* Support creation of Multi-Domain (SAN) Certificates.
* Creation of a Strong Diffie-Hellman Group at startup.
* Work with all versions of docker.

### Requirements:
* Your host **must** be publicly reachable on **both** port `80` and `443`.
* Check your firewall rules and **do not attempt to block port `80`** as that will prevent `http-01` challenges from completing.
* For the same reason, you can't use nginx-proxy's [`HTTPS_METHOD=nohttp`](https://github.com/jwilder/nginx-proxy#how-ssl-support-works).
* The (sub)domains you want to issue certificates for must correctly resolve to the host.
* Your DNS provider must [answer correctly to CAA record requests](https://letsencrypt.org/docs/caa/).
* If your (sub)domains have AAAA records set, the host must be publicly reachable over IPv6 on port `80` and `443`.

![schema](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion/blob/master/schema.png)

## Basic usage (with the nginx-proxy container)

Three writable volumes must be declared on the **nginx-proxy** container so that they can be shared with the **letsencrypt-nginx-proxy-companion** container:

* `/etc/nginx/certs` to store certificates, private keys and ACME account keys (readonly for the **nginx-proxy** container).
* `/etc/nginx/vhost.d` to change the configuration of vhosts (required so the CA may access `http-01` challenge files).
* `/usr/share/nginx/html` to write `http-01` challenge files.

Example of use:

### Step 1 - nginx-proxy

Start **nginx-proxy** with the three additional volumes declared:

```shell
$ docker run --detach \
    --name nginx-proxy \
    --publish 80:80 \
    --publish 443:443 \
    --volume /etc/nginx/certs \
    --volume /etc/nginx/vhost.d \
    --volume /usr/share/nginx/html \
    --volume /var/run/docker.sock:/tmp/docker.sock:ro \
    jwilder/nginx-proxy
```

Binding the host docker socket (`/var/run/docker.sock`) inside the container to `/tmp/docker.sock` is a requirement of **nginx-proxy**.

### Step 2 - letsencrypt-nginx-proxy-companion

Start the **letsencrypt-nginx-proxy-companion** container, getting the volumes from **nginx-proxy** with `--volumes-from`:

```shell
$ docker run --detach \
    --name nginx-proxy-letsencrypt \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --env "DEFAULT_EMAIL=mail@yourdomain.tld" \
    jrcs/letsencrypt-nginx-proxy-companion
```

The host docker socket has to be bound inside this container too, this time to `/var/run/docker.sock`.

Albeit **optional**, it is **recommended** to provide a valid default email address through the `DEFAULT_EMAIL` environment variable, so that Let's Encrypt can warn you about expiring certificates and allow you to recover your account.

### Step 3 - proxyed container(s)

Once both **nginx-proxy** and **letsencrypt-nginx-proxy-companion** containers are up and running, start any container you want proxyed with environment variables `VIRTUAL_HOST` and `LETSENCRYPT_HOST` both set to the domain(s) your proxyed container is going to use.

[`VIRTUAL_HOST`](https://github.com/jwilder/nginx-proxy#usage) control proxying by **nginx-proxy** and `LETSENCRYPT_HOST` control certificate creation and SSL enabling by **letsencrypt-nginx-proxy-companion**.

Certificates will only be issued for containers that have both `VIRTUAL_HOST` and `LETSENCRYPT_HOST` variables set to domain(s) that correctly resolve to the host, provided the host is publicly reachable.

```shell
$ docker run --detach \
    --name your-proxyed-app \
    --env "VIRTUAL_HOST=subdomain.yourdomain.tld" \
    --env "LETSENCRYPT_HOST=subdomain.yourdomain.tld" \
    nginx
```

As for the forced renewal command, replace `nginx-letsencrypt` with the name of your letsencrypt-nginx-proxy-companion container.

#### Optional container environment variables

Optional letsencrypt-nginx-proxy-companion container environment variables for custom configuration.

* `ACME_CA_URI` - Directory URI for the CA ACME API endpoint (default: ``https://acme-v01.api.letsencrypt.org/directory``). If you set it's value to `https://acme-staging.api.letsencrypt.org/directory` letsencrypt will use test servers that don't have the 5 certs/week/domain limits. You can also create test certificates per container (see [let's encrypt test certificates](#test-certificates))

For example

```bash
$ docker run -d \
    -e "ACME_CA_URI=https://acme-staging.api.letsencrypt.org/directory" \
    -v /path/to/certs:/etc/nginx/certs:rw \
    --volumes-from nginx-proxy \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    jrcs/letsencrypt-nginx-proxy-companion
```

* `DEBUG` - Set it to `1` to enable debugging of the entrypoint script and generation of LetsEncrypt certificates, which could help you pin point any configuration issues.

* `RENEW_PRIVATE_KEYS` - Set it to `false` to make simp_le reuse previously generated private key for each certificate instead of creating a new one on certificate renewal. Recommended if you intend to use HPKP.

* The `com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy` label - set this label on the nginx-proxy container to tell the docker-letsencrypt-nginx-proxy-companion container to use it as the proxy.

* The `com.github.jrcs.letsencrypt_nginx_proxy_companion.docker_gen` label - set this label on the docker-gen container to tell the docker-letsencrypt-nginx-proxy-companion container to use it as the docker-gen when it's split from nginx (separate containers).

* `DOCKER_PROVIDER` - Set this to change behavior on container ID retrieval. Optional. Current supported values:
  * No value (empty, not  set): no change in behavior.
  * `ecs` [Amazon ECS using ECS_CONTAINER_METADATA_FILE environment variable](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-metadata.html)

* `DHPARAM_BITS` - Change the size of the Diffie-Hellman key generated by the container from the default value of 2048 bits. For example `-e DHPARAM_BITS=1024` to support some older clients like Java 6 and 7.

#### Examples:

## Additional documentation

Please check the [docs section](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion/tree/master/docs) or the [project's wiki](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion/wiki).
