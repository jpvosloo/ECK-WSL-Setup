Garbage file - to deltee
wget -O /usr/local/bin/pacapt https://github.com/icy/pacapt/raw/ng/pacapt



wget http://elasticsearch-es-http.default.svc.cluster.local:9200
nslookup elasticsearch-es-http.default.svc.cluster.local

wget --no-check-certificate "https://elasticsearch-es-http.default.svc.cluster.local:9200"
curl --insecure get "https://elasticsearch-es-http.default.svc.cluster.local:9200"