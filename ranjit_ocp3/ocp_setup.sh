#!/bin/bash
rm -f log
echo "First must download openshift client, installer and docker-compose in current path"
subscription-manager register --username ssumit7 --password bmw_3131 --auto-attach
yum repolist |grep "This system is not registered"
if [ $? -eq 0 ]
then
echo " Subscription is not Confgured in this VM................."
exit 1
fi
host_ip=`cat input.txt |grep host_ip|awk -F"=" '{print $NF}'`
dtstor=`cat input.txt |grep host_ip|awk -F"=" '{print $NF}'|cut -d"." -f4`
new_lb_ip=`cat input.txt |grep loadbalancer|awk -F"=" '{print $NF}'`
master1=`cat input.txt |grep master1|awk -F"=" '{print $NF}'`
master2=`cat input.txt |grep master2|awk -F"=" '{print $NF}'`
master3=`cat input.txt |grep master3|awk -F"=" '{print $NF}'`
worker1=`cat input.txt |grep worker1|awk -F"=" '{print $NF}'`
worker2=`cat input.txt |grep worker2|awk -F"=" '{print $NF}'`
worker3=`cat input.txt |grep worker3|awk -F"=" '{print $NF}'`
worker4=`cat input.txt |grep worker4|awk -F"=" '{print $NF}'`
openshift=`cat input.txt |grep openshift|awk -F"=" '{print $NF}'`
bootstrap=`cat input.txt |grep bootstrap|awk -F"=" '{print $NF}'`

rev_master1=`echo $master1 | perl -lne 'print join ".", reverse split/\./;'`
rev_master2=`echo $master2| perl -lne 'print join ".", reverse split/\./;'`
rev_master3=`echo $master3 | perl -lne 'print join ".", reverse split/\./;'`
rev_worker1=`echo $worker1 | perl -lne 'print join ".", reverse split/\./;'`
rev_worker2=`echo $worker2 | perl -lne 'print join ".", reverse split/\./;'`
rev_worker3=`echo $worker3 | perl -lne 'print join ".", reverse split/\./;'`
rev_worker4=`echo $worker4 | perl -lne 'print join ".", reverse split/\./;'`
rev_lb_ip=`echo $new_lb_ip | perl -lne 'print join ".", reverse split/\./;'`
rev_bootstrap=`echo $bootstrap | perl -lne 'print join ".", reverse split/\./;'`

echo "docker-compose.yaml file created in /opt/dns" |tee -a log
rm -rf /opt/dns
rm -rf /opt/openshift-install
mkdir -p /opt/dns/config
mkdir -p /opt/openshift_install/cli

echo " docker-compose.yaml file creating -----------" |tee -a log
echo "version: '3.3'
services:
  coredns-service:
    network_mode: host
    ports:
      - \"$new_lb_ip:53:53\"
      - \"$new_lb_ip:53:53/udp\"
    image: yorickps/coredns:latest
    restart: always
    expose:
      - \"53\"
      - \"53/udp\"
    volumes:
      - type: bind
        source: /opt/dns/config
        target: /etc/coredns
      - type: bind
        source: /opt/dns/config/db.$openshift.icdlab.com
        target: /db.$openshift.icdlab.com
      - type: bind
        source: /opt/dns/config/reverse.$openshift
        target: /reverse.$openshift">/opt/dns/docker-compose.yaml



echo "Corefile creating -------------------"|tee -a log
echo "$openshift.icdlab.com:53 {
    bind $new_lb_ip 
    file db.$openshift.icdlab.com
}
152.20.172.in-addr.arpa {
    bind $new_lb_ip
    file reverse.$openshift
}

.:53 {
    bind $new_lb_ip 
    forward . 10.8.11.12:53 10.8.11.13:53
}" >/opt/dns/config/Corefile

echo " db.$openshift.icdlab.com creating --------------"|tee -a log
echo "\$ORIGIN $openshift.icdlab.com.
@       3600 IN SOA $new_lb_ip $new_lb_ip. (
                                2017042745 ; serial
                                7200       ; refresh (2 hours)
                                3600       ; retry (1 hour)
                                1209600    ; expire (2 weeks)
                                3600       ; minimum (1 hour)
                                )
worker1 IN A $worker1
worker2 IN A $worker2
worker3 IN A $worker3
worker4 IN A $worker4


bootstrap IN A $bootstrap

master1 IN A $master1
master2 IN A $master2
master3 IN A $master3

api IN A $new_lb_ip
api-int IN A $new_lb_ip
*.apps IN A $new_lb_ip
">/opt/dns/config/db.$openshift.icdlab.com

echo " reverse.$openshift creating ------------"|tee -a log
echo "\$ORIGIN 152.20.172.in-addr.arpa.
@       3600 IN SOA $new_lb_ip $new_lb_ip (
                                2017042745 ; serial
                                7200       ; refresh (2 hours)
                                3600       ; retry (1 hour)
                                1209600    ; expire (2 weeks)
                                3600       ; minimum (1 hour)
                                )

$rev_bootstrap.in-addr.arpa. 3600 IN PTR bootstrap.$openshift.icdlab.com.
$rev_master1.in-addr.arpa. 3600 IN PTR master1.$openshift.icdlab.com.
$rev_master2.in-addr.arpa. 3600 IN PTR master2.$openshift.icdlab.com.
$rev_master3.in-addr.arpa. 3600 IN PTR master3.$openshift.icdlab.com.

$rev_worker1.in-addr.arpa. 3600 IN PTR worker1.$openshift.icdlab.com.
$rev_worker2.in-addr.arpa. 3600 IN PTR worker2.$openshift.icdlab.com.
$rev_worker3.in-addr.arpa. 3600 IN PTR worker3.$openshift.icdlab.com.
$rev_worker4.in-addr.arpa. 3600 IN PTR worker4.$openshift.icdlab.com.

$rev_lb_ip.in-addr.arpa. 3600 IN PTR api.$openshift.icdlab.com.
$rev_lb_ip.in-addr.arpa. 3600 IN PTR api-int.$openshift.icdlab.com.">/opt/dns/config/reverse.$openshift

echo " /etc/hosts file configuring -------------"|tee -a log

echo "$new_lb_ip  sls.ibm-sls.ibm-sls.apps.$openshift.icdlab.com
$new_lb_ip  api.$openshift.icdlab.com api-int.$openshift.icdlab.com *.apps.$openshift.icdlab.com $openshift.icdlab.com
$bootstrap   bootstrap.$openshift.icdlab.com
$worker1   worker1.$openshift.icdlab.com
$worker2   worker2.$openshift.icdlab.com
$worker3   worker3.$openshift.icdlab.com
$worker4   worker4.$openshift.icdlab.com
$master1   master1.$openshift.icdlab.com etcd-0.$openshift.icdlab.com
$master2   master2.$openshift.icdlab.com etcd-1.$openshift.icdlab.com
$master3   master3.$openshift.icdlab.com etcd-2.$openshift.icdlab.com" >>/etc/hosts

echo " installing haproxy ------------"|tee -a log
yum remove haproxy -y
yum install haproxy -y
if [ $? -ne 0 ]
then
echo "install haproxy Failed......"|tee -a log
fi
echo " configuring /etc/haproxy/haproxy.cfg file ------------"|tee -a log

mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg_bkp

echo "
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  dontlognull
    option http-server-close
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
#frontend  main *:5000
#    acl url_static       path_beg       -i /static /images /javascript /stylesheets
#    acl url_static       path_end       -i .jpg .gif .png .css .js

#    use_backend static          if url_static
#    default_backend             app

#---------------------------------------------------------------------
# static backend for serving up images, stylesheets and such
#---------------------------------------------------------------------
#backend static
#    balance     roundrobin
#    server      static 10.160.161.160:4331 check

#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
#backend app
#    balance     roundrobin
#    server  app1 127.0.0.1:5001 check
#    server  app2 127.0.0.1:5002 check
#    server  app3 127.0.0.1:5003 check
#    server  app4 127.0.0.1:5004 check


frontend stats
  bind *:1936
  mode            http
  log             global
  maxconn 10
  stats enable
  stats hide-version
  stats refresh 30s
  stats show-node
  stats show-desc Stats for $openshift cluster
  stats auth admin:openshift
  stats uri /stats

listen api-server-6443
  bind *:6443
  mode tcp

    server bootstrap bootstrap.$openshift.icdlab.com:6443 inter 1s backup
    server master1 master1.$openshift.icdlab.com:6443 check inter 1s
    server master2 master2.$openshift.icdlab.com:6443 check inter 1s
    server master3 master3.$openshift.icdlab.com:6443 check inter 1s

listen machine-config-server-22623
  bind *:22623
  mode tcp
    server bootstrap bootstrap.$openshift.icdlab.com:22623 check inter 1s backup
    server master1 master1.$openshift.icdlab.com:22623 check inter 1s
    server master2 master2.$openshift.icdlab.com:22623 check inter 1s
    server master3 master3.$openshift.icdlab.com:22623 check inter 1s

listen ingress-router-443
  bind *:443
  mode tcp
  balance source
    server worker1 worker1.$openshift.icdlab.com:443 check inter 1s
    server worker2 worker2.$openshift.icdlab.com:443 check inter 1s
    server worker3 worker3.$openshift.icdlab.com:443 check inter 1s
    server worker4 worker4.$openshift.icdlab.com:443 check inter 1s

listen ingress-router-80
  bind *:80
  mode tcp
  balance source
    server worker1 worker1.$openshift.icdlab.com:80 check inter 1s
    server worker2 worker2.$openshift.icdlab.com:80 check inter 1s
    server worker3 worker3.$openshift.icdlab.com:80 check inter 1s
    server worker4 worker4.$openshift.icdlab.com:80 check inter 1s" >/etc/haproxy/haproxy.cfg

#sed -i 's/openshift[a-z][a-z][0-1]/'$openshift'/g' /etc/haproxy/haproxy.cfg
#cp haproxy.cfg /etc/haproxy/

echo " configuring oc cli command --------" |tee -a log
pwd
cp oc-* /opt/openshift_install/cli
cd /opt/openshift_install/cli && tar -xvf oc-*
cp oc /usr/local/bin
#rm -rf /root/.ssh/id_rsa
cd && ssh-keygen -t ed25519 -N '' -f  ~/.ssh/id_rsa
ssh-add  ~/.ssh/id_rsa
rsa_key=`cat ~/.ssh/id_rsa.pub`
echo $rsa_key
echo "------------ install.config file configuring ----------"|tee -a log

echo "apiVersion: v1
baseDomain: icdlab.com
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  name: $openshift 
platform:
  vsphere:
    vcenter: 172.20.150.51
    username: ocpadmin1@ta.com
    password: Test@123!
    datacenter: ICD-TADDM-VSBL2
    defaultDatastore: VM_Images$dtstor
pullSecret: '{\"auths\":{\"cloud.openshift.com\":{\"auth\":\"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2Nlc3NfYzAxOTQzZWJkMTFhNDkzNmJjOTUzOWMwZmJhM2ViOTM6QlJDQ1VWTDlVTEMzUk9SVkpUUElES1dCTlhFT0ZLMVdSTEJRREQzVDMyUDlBUE1QWDhPVzA2OTdHTktLN1VNMw==\",\"email\":\"nikhil.walia@capgemini.com\"},\"quay.io\":{\"auth\":\"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2Nlc3NfYzAxOTQzZWJkMTFhNDkzNmJjOTUzOWMwZmJhM2ViOTM6QlJDQ1VWTDlVTEMzUk9SVkpUUElES1dCTlhFT0ZLMVdSTEJRREQzVDMyUDlBUE1QWDhPVzA2OTdHTktLN1VNMw==\",\"email\":\"nikhil.walia@capgemini.com\"},\"registry.connect.redhat.com\":{\"auth\":\"fHVoYy1wb29sLWE1MmE1NDZhLWI2MjUtNGMxNy04ZjI4LTliMTBjOTc5YjJjMzpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSmlORGM0Tm1SbFlUSmpORGcwWXpRNU9UYzROVGczWldJM01UbGhNRGt3TlNKOS5KbkJXdDZfWjFSTHRVNUhGbzdIczBNd2ZXV2swRm5XYWhqNXhld0RUd2daemJqTjgzSDBUR19XdjVPemRrb2JWUFAtMkxSaXNicUdYWHpaTWNmRU5FeERSd0NTbVU0YUNxaWdNZWlpVHNCNTdOM1daTmdzV0RndlNhNDZVcUNUcWJvNmlBTmM1eDBIYzROQVNQN05zUGxMVklqT1NhLVpWVm1SNmswSEFQazVRaER4VVVQYjdDX1p5LW5UUTV1VU5MXzhsRXlQVnc1dFRjV3RxUVQzZWRqUk9RZTBmWGZEVkp0dmc2eW1faUpxbkdnSFY1SHNHSmZDLWNiVTk4OXloY1RDNXFCNDdQZktBZm1Gc2c2OFhCQllWRTEzMVJIWWM5OUEwQUlFWFQyelkyNF9MQVViNVJKVHRHY21ROW5YSmhOWnV4MTN4N09KWEwxb0EwUy13anJkWms1RjR3d3Q2Yk52TzRrR3BmSmxETGg4bzliQU1fNFNmdmxjSmZ0eTBENkZhdGVLa01NbzJVcWpaOWZrUW9jcFhKQUg5b0loS2pIa0ZHZDdMWDlkSVplSkdXLV8xb3dMd2dVc21qZFJQX3RXdWVUcEZDQmtuRi12NGNnZXJia1BwOE5TMHcteF9TVEo4VmNzbHdCZmJ2bmlta3FGd3lHanJTbGIwRlZMRWtUcXAtUEV1bHFNd2dpNkUxSjdHTURuZFU0bVBwN0d6XzB5Q2xueTQ5TUJ0MmotT2RMak85czN5NEtjUU1ySG5Vb3E1R1ptMjNXUElxMXRaU0o5WXFBempVbmJpYVlsaEs5UzlIa2hyZU11YktoUTc2UmpHWkZRaGtDdklkRDlHRjBDWUhFUTduX3pHSDlrTWsxUGFPV3g4NldMQ3JYZ284dTFOQ2lXNnowaw==\",\"email\":\"nikhil.walia@capgemini.com\"},\"registry.redhat.io\":{\"auth\":\"fHVoYy1wb29sLWE1MmE1NDZhLWI2MjUtNGMxNy04ZjI4LTliMTBjOTc5YjJjMzpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSmlORGM0Tm1SbFlUSmpORGcwWXpRNU9UYzROVGczWldJM01UbGhNRGt3TlNKOS5KbkJXdDZfWjFSTHRVNUhGbzdIczBNd2ZXV2swRm5XYWhqNXhld0RUd2daemJqTjgzSDBUR19XdjVPemRrb2JWUFAtMkxSaXNicUdYWHpaTWNmRU5FeERSd0NTbVU0YUNxaWdNZWlpVHNCNTdOM1daTmdzV0RndlNhNDZVcUNUcWJvNmlBTmM1eDBIYzROQVNQN05zUGxMVklqT1NhLVpWVm1SNmswSEFQazVRaER4VVVQYjdDX1p5LW5UUTV1VU5MXzhsRXlQVnc1dFRjV3RxUVQzZWRqUk9RZTBmWGZEVkp0dmc2eW1faUpxbkdnSFY1SHNHSmZDLWNiVTk4OXloY1RDNXFCNDdQZktBZm1Gc2c2OFhCQllWRTEzMVJIWWM5OUEwQUlFWFQyelkyNF9MQVViNVJKVHRHY21ROW5YSmhOWnV4MTN4N09KWEwxb0EwUy13anJkWms1RjR3d3Q2Yk52TzRrR3BmSmxETGg4bzliQU1fNFNmdmxjSmZ0eTBENkZhdGVLa01NbzJVcWpaOWZrUW9jcFhKQUg5b0loS2pIa0ZHZDdMWDlkSVplSkdXLV8xb3dMd2dVc21qZFJQX3RXdWVUcEZDQmtuRi12NGNnZXJia1BwOE5TMHcteF9TVEo4VmNzbHdCZmJ2bmlta3FGd3lHanJTbGIwRlZMRWtUcXAtUEV1bHFNd2dpNkUxSjdHTURuZFU0bVBwN0d6XzB5Q2xueTQ5TUJ0MmotT2RMak85czN5NEtjUU1ySG5Vb3E1R1ptMjNXUElxMXRaU0o5WXFBempVbmJpYVlsaEs5UzlIa2hyZU11YktoUTc2UmpHWkZRaGtDdklkRDlHRjBDWUhFUTduX3pHSDlrTWsxUGFPV3g4NldMQ3JYZ284dTFOQ2lXNnowaw==\",\"email\":\"nikhil.walia@capgemini.com\"}}}'
sshKey: '$rsa_key'">/opt/openshift_install/cli/install-config.yaml

cp /opt/openshift_install/cli/install-config.yaml /opt/openshift_install/install-config.yaml
echo "-----------openshift-installing ----------"|tee -a log
pwd
cp /opt/ranjit/openshift-install-linux* /opt/openshift_install 

cd /opt/openshift_install && tar -xvf openshift-install-linux*

ls -ltr && rm -rf *.tar.gz
echo "create manifests file"|tee -a log
sleep 5
cd /opt/openshift_install 
./openshift-install create manifests --dir .
if [ $? -ne 0 ]
then
echo "openshift-install create manifests Failed............"|tee -a log
fi
cd /opt/openshift_install && ls -ltr |tee -a log
rm -f openshift-install-linux.tar.gz README.md
rm -f openshift/99_openshift-cluster-api_master-machines-*.yaml openshift/99_openshift-cluster-api_worker-machineset-*.yaml
sed -i 's/: true/: false/g' ./manifests/cluster-scheduler-02-config.yml 

echo " creating ignition-configs file ---------------"|tee -a log
sleep 8
cd /opt/openshift_install 
./openshift-install create ignition-configs --dir .
if [ $? -ne 0 ]
then
echo "openshift-install create ignition-configs Failed............"|tee -a log
fi
cd /opt/openshift_install && ls -ltr |tee -a log
echo " installing httpd ---------------"|tee -a log
yum remove httpd -y
yum install httpd -y
if [ $? -ne 0 ]
then
echo "install httpd Failed..........."|tee -a log
fi
sed -i 's/80/8080/g' /etc/httpd/conf/httpd.conf
cp bootstrap.ign /var/www/html && chmod 777 /var/www/html/bootstrap.ign
systemctl start httpd
systemctl enable httpd
systemctl status httpd
echo "http://$new_lb_ip:8080/bootstrap.ign"|tee -a log          

echo " creating merge-bootstrap.ign -----------------"|tee -a log
echo "{
  \"ignition\": {
    \"config\": {
      \"merge\": [
        {
          \"source\": \"http://$new_lb_ip:8080/bootstrap.ign\",
          \"verification\": {}
        }
      ]
    },
    \"timeouts\": {},
    \"version\": \"3.2.0\"
  },
  \"networkd\": {},
  \"passwd\": {},
  \"storage\": {},
  \"systemd\": {}
}" >/opt/openshift_install/merge-bootstrap.ign
cd /opt/openshift_install/
base64 -w0 ./master.ign > ./master.64
base64 -w0 ./worker.ign > ./worker.64
base64 -w0 ./merge-bootstrap.ign > ./merge-bootstrap.64

echo "--- configuring docker --------------"|tee -a log
yum repolist
yum check-update
yum install docker
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine \
                  podman \
                  runc -y


sudo yum config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
systemctl start docker
systemctl enable docker
echo "configuring docker-compose"|tee -a log
cd /opt/ranjit/
cp docker-compose /usr/local/bin
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
echo "docker-compose version"|tee -a log
docker-compose --version
cd /opt/dns
docker-compose up -d
if [ $? -ne 0 ]
then
echo "docker-compose up -d Failed........."|tee -a log
fi
docker ps
systemctl stop haproxy
systemctl start haproxy
setsebool -P haproxy_connect_any=1
systemctl start haproxy
systemctl enable haproxy
systemctl status haproxy
sed -i 's/^/#/g' /etc/resolv.conf
sed -i '2inameserver '$new_lb_ip'' /etc/resolv.conf
echo - "\n\n############### all service status ##############"|tee -a log
echo "dns status"
docker ps
echo "docker status"
systemctl status docker
echo "httpd status"
systemctl status httpd
echo "haproxy status"
systemctl status haproxy
echo "----------END-----------"
