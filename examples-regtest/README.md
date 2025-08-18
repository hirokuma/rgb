# examples-regtest

## prepare

### bitcoind

* bitcoin.conf

```
server=1
txindex=1
regtest=1

zmqpubrawblock=tcp://127.0.0.1:28332
zmqpubrawtx=tcp://127.0.0.1:28333

[regtest]
rpcuser=testuser
rpcpassword=testpass
fallbackfee=0.000001

# SPV
blockfilterindex=1
peerblockfilters=1
```

* start-new-bitcoind.sh

```bash
#!/bin/bash

rm -rf $HOME/.bitcoin/regtest
bitcoind -daemon

while :
do
        bitcoin-cli getblockcount > /dev/null 2>&1
        if [ "$?" -eq 0 ]; then
                break
        fi
        echo -n "."
        sleep 1
done
echo

bitcoin-cli createwallet ""
./generate.sh 101
```

### Blockstream/electrs

* start-electrs.sh

```
#!/bin/bash

while :
do
        dl=`bitcoin-cli getblockchaininfo | jq .initialblockdownload`
        if [ "$dl" == "false" ]; then
                break
        fi
        echo -n "."
        sleep 3
done
echo

ELECTRS=electrs

DATADIR="$HOME/.bitcoin/regtest/electrs"
NETWORK="regtest"
RPCUSER="testuser"
RPCPASS="testpass"
ZMQ_ADDR="localhost:28332"
ELECTRUM_URL="localhost:50001"
REST_URL="0.0.0.0:3002"
ESPLORA_URL="*"

$ELECTRS --db-dir="$DATADIR" \
    --network="$NETWORK" \
    --cookie="${RPCUSER}:${RPCPASS}"  \
    --zmq-addr="$ZMQ_ADDR" \
    --electrum-rpc-addr="$ELECTRUM_URL" \
    --http-addr="$REST_URL" \
    --cors="$ESPLORA_URL"
```

## demo

```console
$ ./examples-regtest/demo.sh
```
