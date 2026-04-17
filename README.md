# Homework №2 in the course "Industrial Software Development"

## Run
    docker build -t custom-app:1.1 .
    chmod +x deploy.sh
    ./deploy.sh

## Test API

    kubectl port-forward -n logging-hw svc/custom-app-service 8080:80

In another terminal:

    curl -i http://127.0.0.1:8080/
    curl -i http://127.0.0.1:8080/status

    curl -i -X POST http://127.0.0.1:8080/log \
    -H 'Content-Type: application/json' \
    -d '{"message":"direct service call works"}'

    curl -i http://127.0.0.1:8080/logs

    for i in {1..10}; do
    curl -s -D - http://127.0.0.1:8080/status -o /dev/null | grep X-Pod-Name
    done


## Test Istio Gateway

    kubectl port-forward -n istio-system svc/istio-ingressgateway 8081:80

In another terminal:

    curl -i http://127.0.0.1:8081/
    curl -i http://127.0.0.1:8081/status
    curl -i http://127.0.0.1:8081/logs

    curl -i http://127.0.0.1:8081/wrong

    time curl -i -X POST http://127.0.0.1:8081/log \
    -H 'Content-Type: application/json' \
    -d '{"message":"through istio gateway"}'

Last one expects: HTTP 504 Gateway Timeout

