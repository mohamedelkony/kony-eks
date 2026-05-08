kubectl apply -k ./manifests/base-application

helm repo add prometheus-community \
https://prometheus-community.github.io/helm-charts

helm install monitoring \
prometheus-community/kube-prometheus-stack