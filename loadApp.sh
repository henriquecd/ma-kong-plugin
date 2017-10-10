# RegisterComponent
(curl http://localhost:8001/apis -s -S -X POST \
    --header "Content-Type: application/json" \
    -d @- | python -m json.tool) <<PAYLOAD
{
    "name": "kerberos_loadApp",
    "uris": "/kerberos/loadApp",
    "strip_uri": true,
    "upstream_url": "http://kerberos:8080/kerberosintegration/rest/health/status"
}
PAYLOAD

curl -i -X POST \
    --url http://localhost:8001/apis/kerberos_loadApp/plugins/ \
    --data 'name=mutualauthentication' \
    --data 'config.kerberos_url=http://kerberos:8080/' \
    --data 'config.app_id=deadbeefdeadbeef' \
    --data 'config.app_key=deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
      
curl http://localhost:8000/kerberos/loadApp -s -S -X GET
