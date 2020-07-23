---
title: "SSL/TLS RGW Configuration on Octopus Ceph Cluster"
date: 2020-07-23T01:23:25+02:00
type: post
summary: Setting up SSL/TLS on my RADOS Gateway (RGW) Ceph Octopus cluster was a PITA, here's how I did it!
categories:
- cloud
- infrastructure
- snippet
tags:
- ceph
- storage
---

Ceph v15.2 aka. Octopus was released this year and along with it a new way of installing Ceph - cephadm.
Ceph is slowly moving service configuration to the orchestrator (e.g. Rook, cephadm) interface.
What this means is that you no longer configure services (i.e. RADOS Gateway - RGW) by editing the `ceph.conf` 
file but rather you use the `ceph` CLI to store configs into a key-value store.

## Configuring SSL/TLS for your RGW Instance
1. Have your RGW's valid SSL/TLS certificate ready on a machine that has access to the `ceph` CLI[^1].
2. Run the following commands, replacing the RGW realm, zone and certificate files:
{{< highlight shell >}}
$ ceph config-key set rgw/cert/<rgw_realm>/<rgw_zone>.crt -i <cert_file>  # replace with .pem certificate
$ ceph config-key set rgw/cert/<rgw_realm>/<rgw_zone>.key -i <key_file>   # replace with .pem private key
$ ceph config set client.rgw.<rgw_realm>.<rgw_zone> rgw_frontends "beast port=80 ssl_port=443 ssl_certificate=config://rgw/cert/<rgw_realm>/<rgw_zone>.key ssl_private_key=config://rgw/cert/<rgw_realm>/<rgw_zone>.key"
{{< /highlight >}}
3. Restart the RGW, e.g. `ceph orch restart rgw`


[^1]: With the cephadm instalaltion, this will most probably be your bootstrapping server (also probably your monitor node).
Gaining access to the `ceph` CLI tool is usually done by running `cephadm shell` which drops you into a Docker/Podman container 
with the `ceph` CLI tool available. The container actually has a host filesystem bind mount `/var/lib/ceph/<CEPH_ID>/home:/root`.
Copying your RGW SSL/TLS certificate on the bootstrap machine in the aforementioned dir will make the certificate available in
the `cephadm shell`'s container in the `/root` dir.


## Other RGW Configuration Settings
Configuring using `ceph config` requires three parameters:
1. Who - `client.rgw.<rgw_realm>.<rgw_zone>`
2. Option - the setting you are configuring
3. Value - the value of the setting

RGW options can be either found in the [documentation](https://docs.ceph.com/docs/octopus/radosgw/config-ref/) and/or 
consulting the output of `ceph config ls | grep -i rgw`. 

See `ceph config -h` for general configuration details (scroll towards the end of the output).
