Test Pulp is a single bare metal `pulp-server` instance in SMS Lab's `stackhpc-release` project.

It can be reached via SMS Lab's bastion host:
```
ssh centos@10.205.3.187 -J 185.45.78.150
```
If your SSH key is not there, ask for access on #release-train Slack channel.

It utilises an all-in-one Pulp container run via podman:
```
podman run --name pulp \
  --volume /etc/pulp:/etc/pulp \
  -p 8080:80 \
  -p 24817:24817 \
  --volume pulp_storage:/var/lib/pulp \
  --volume pulp_pgsql:/var/lib/pgsql \
  --volume pulp_containers:/var/lib/containers \
  --shm-size=1g \
  pulp/pulp

CONTAINER ID  IMAGE                       COMMAND  CREATED       STATUS             PORTS                                           NAMES
3ab31fcb4221  docker.io/pulp/pulp:latest           5 months ago  Up 16 minutes ago  0.0.0.0:8080->80/tcp, 0.0.0.0:24817->24817/tcp  pulp
```
Pretty basic setup done manually, with the following `/etc/pulp/settings.py`config file:
```
CONTENT_ORIGIN='http://10.205.3.187:8080'
ANSIBLE_API_HOSTNAME='http://10.205.3.187:8080'
ANSIBLE_CONTENT_HOSTNAME='http://10.205.3.187:8080/pulp/content'
TOKEN_AUTH_DISABLED=True
TOKEN_SERVER='http://10.205.3.187:24817/token'
ALLOWED_CONTENT_CHECKSUMS = ["sha1", "sha224", "sha256", "sha384", "sha512"]
```
