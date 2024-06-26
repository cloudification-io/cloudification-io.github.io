#!/bin/bash

openstack_infra_apps="memcached
openvswitch
ovn
libvirt
helm-toolkit
ceph-rgw"

openstack_apps="cinder
glance
heat
horizon
keystone
nova
placement
neutron
octavia"

for chart in $(echo ${openstack_infra_apps}); do
     echo "Build Chart for openstack-helm-infra/$chart"
     helm package ./openstack-helm-infra/$chart --dependency-update
done

for chart in $(echo ${openstack_apps}); do
     echo "Build Chart for openstack-helm/$chart"
     helm package ./openstack-helm/$chart --dependency-update
done

echo "Building Chart for Openstack exporter"
helm package ./openstack-exporter/charts/prometheus-openstack-exporter --dependency-update

helm repo index . --url https://cloudification-io.github.io

sed -i 's/file:.*helm-toolkit/https:\/\/cloudification-io.github.io/g' index.yaml
