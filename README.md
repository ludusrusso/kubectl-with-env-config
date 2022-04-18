# Kubectl docker image with base64 KUBECONFIG

This is a simple image with kubectl that allow passing kubeconfig base64 encoded via env variables and perform port forwarding on a given pod and port.

This is meant to be use as a service in a github action to connect to serviced hosted on a remote kubernetes cluster.

You can generate an encoded kubeconfig for this container using [this script](./get-config.bash)
