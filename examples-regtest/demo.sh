#!/usr/bin/env bash

set -xe

cargo build --workspace --all-targets
export RUST_BACKTRACE=1

EXAMDIR=examples-regtest

USER1=carol
USER2=dave
TOKENNAME="DemoTokenRegtest"
DATADIR1=${EXAMDIR}/data3
DATADIR2=${EXAMDIR}/data4

RGB="./target/debug/rgb -d ${DATADIR1} -n regtest"
RGB_2="./target/debug/rgb -d ${DATADIR2} -n regtest"
INDEXER="--electrum=localhost:50001"

rm -f \
    ${EXAMDIR}/DemoToken.rgb \
    ${EXAMDIR}/transfer.psbt \
    ${EXAMDIR}/transfer.rgb \
    ${EXAMDIR}/DemoToken-work.yaml
rm -rf \
    ${DATADIR1} \
    ${DATADIR2}

$RGB init
$RGB_2 init

WALLET1=$(bitcoin-cli listdescriptors false | jq -r '[.descriptors[] | select(.desc | test("^wpkh")) | .desc][0] | sub("^wpkh\\("; "") | sub("\\)#.*$"; "")')
WALLET2=$(bitcoin-cli listdescriptors false | jq -r '[.descriptors[] | select(.desc | test("^wpkh")) | .desc][1] | sub("^wpkh\\("; "") | sub("\\)#.*$"; "")')
$RGB create ${USER1}.wallet ${WALLET1} --wpkh
$RGB_2 create ${USER2}.wallet ${WALLET2} --wpkh

# set UTXO outPoint
ADDR=`$RGB fund ${USER1}`
TXID=`bitcoin-cli sendtoaddress $ADDR 0.005`
bitcoin-cli generatetoaddress 1 $ADDR
DETAILS=`bitcoin-cli gettransaction $TXID | jq -c .details`
VOUT=`echo $DETAILS | jq '.[] | select(.category == "send") | .vout'`
cat ${EXAMDIR}/DemoToken.yaml | sed -e "s/OUTPOINT/${TXID}:${VOUT}/" > ${EXAMDIR}/DemoToken-work.yaml
sed -i  -e "s/\[set\]/\[set\]\n\"${TXID}:${VOUT}\" = \[500000, \"\&0\/1\"\]/" ${DATADIR1}/bitcoin.testnet/${USER1}.wallet/utxo.toml

ADDR=`$RGB_2 fund ${USER2}`
TXID=`bitcoin-cli sendtoaddress $ADDR 0.005`
bitcoin-cli generatetoaddress 1 $ADDR
DETAILS=`bitcoin-cli gettransaction $TXID | jq -c .details`
VOUT=`echo $DETAILS | jq '.[] | select(.category == "send") | .vout'`
sed -i  -e "s/\[set\]/\[set\]\n\"${TXID}:${VOUT}\" = \[500000, \"\&0\/1\"\]/" ${DATADIR2}/bitcoin.testnet/${USER2}.wallet/utxo.toml

# RGB20-FNA
# https://github.com/pandora-prime/rgb-issuers/blob/49b4048cdffb93fd84161713891d3d8fa02f7eaf/compiled/RGB20-Simplest-v0-AYkSrg.issuer
$RGB import ${EXAMDIR}/RGB20-FNA.issuer
$RGB issue -w ${USER1} ${EXAMDIR}/DemoToken-work.yaml
$RGB backup -f ${TOKENNAME} ${EXAMDIR}/DemoToken.rgb
$RGB_2 accept -w ${USER2} -u ${EXAMDIR}/DemoToken.rgb

$RGB contracts
$RGB state -go -w ${USER1} ${INDEXER}
$RGB_2 contracts
$RGB_2 state -go -w ${USER2} ${INDEXER}

AUTH_TOKEN=$($RGB_2 invoice -w ${USER2} --nonce 0 --seal-only ${TOKENNAME})
INVOICE=$($RGB_2 invoice -w ${USER2} --nonce 0 ${TOKENNAME} 10)
$RGB pay -w ${USER1} "$INVOICE" ${EXAMDIR}/transfer.rgb ${EXAMDIR}/transfer.psbt ${INDEXER}
$RGB_2 accept -w ${USER2} ${EXAMDIR}/transfer.rgb

$RGB state -goa -w ${USER1}
$RGB_2 state -go -w ${USER2}
