POD=$1
NAMESPACE=$2

out=`kubectl get pod $POD -n $NAMESPACE 2>&1`

if [[ $out =~ "NotFound" ]]; then
    echo "pod $POD does not exist in namespace $NAMESPACE. Aborting"
	exit 1
fi


cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $POD-forward
  namespace: $NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: $POD-forward
  namespace: $NAMESPACE
rules:
  - apiGroups: [""]
    resources: ["pods"]
    resourceNames: ["$POD"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["pods/portforward"]
    resourceNames: ["$POD"]
    verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $POD-forward
  namespace: $NAMESPACE
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $POD-forward
subjects:
  - kind: ServiceAccount
    name: $POD-forward
    namespace: $NAMESPACE
EOF

TOKENNAME=`kubectl -n $NAMESPACE get serviceaccount/$POD-forward -o jsonpath='{.secrets[0].name}'`
TOKEN=`kubectl -n $NAMESPACE get secret/$TOKENNAME -o jsonpath='{.data.token}' | base64 -d`
SERVER=`kubectl config view --minify --output jsonpath="{.clusters[*].cluster.server}"`
CA=`kubectl config view --minify --flatten  --output jsonpath="{.clusters[*].cluster.certificate-authority-data}"`

cat <<EOF | base64 -
apiVersion: v1
clusters:
  - cluster:
      server: $SERVER
      certificate-authority-data: $CA
    name: kubernetes
contexts:
  - context:
      cluster: kubernetes
      user: $POD-forward-sa
    name: target-cluster
current-context: target-cluster
kind: Config
preferences: {}
users:
  - name: $POD-forward-sa
    user:
      token: $TOKEN
EOF