#!/bin/bash

for chart in memcached openvswitch ovn libvirt helm-toolkit; do
     helm package ../openstack-helm-infra/$chart
done

for chart in cinder glance heat horizon keystone nova placement neutron; do
     helm package ../openstack-helm/$chart
done

helm repo index . --url https://cloudification-io.github.io

sed -i 's/file:.*helm-toolkit/https:\/\/cloudification-io.github.io/g' index.yaml