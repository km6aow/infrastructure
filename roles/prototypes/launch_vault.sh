#!/bin/bash
#
export VAULT_ADDR=http://127.0.0.1:8200
docker run --cap-add=IPC_LOCK \
  --env \
    'VAULT_LOCAL_CONFIG={ 
      "storage": 
         {
          "file": 
                  {
                    "path": "/vault/file"
                  }
          }, 
      "listener": [
          {
            "tcp": { 
                    "address": "0.0.0.0:8200", 
                    "tls_disable": true
                   }
          }
       ], 
       "default_lease_ttl": "168h", 
       "max_lease_ttl": "720h", 
       "ui": true
      }' \
  --publish 8200:8200 \
  --detach \
  --name vault_dev \
  --volume /vault:/vault \
  hashicorp/vault server

if [ $? -eq 0 ] ; then
    echo container running. Initialize it
    sleep 2
    vault operator init --address="${VAULT_ADDR}" > /tmp/vault_init

    if [ $? -eq 0 ] ; then
        echo vault initialized
        key1=$(pcregrep --only-matching=1 '.*Unseal Key 1:\s+(.*)' /tmp/vault_init)
        key2=$(pcregrep --only-matching=1 '.*Unseal Key 2:\s+(.*)' /tmp/vault_init)
        key3=$(pcregrep --only-matching=1 '.*Unseal Key 3:\s+(.*)' /tmp/vault_init)
        VAULT_TOKEN=$(pcregrep --only-matching=1 '.*Token:\s+(.*)' /tmp/vault_init)

        echo Key1: ${key1}
        echo Key2: ${key2}
        echo Key3: ${key3}
        echo Token: ${VAULT_TOKEN}
        vault operator unseal ${key1}
        vault operator unseal ${key2}
        vault operator unseal ${key3}
        vault secrets enable -path=secret kv

    fi
fi
