#!/bin/bash

EXAMDIR=examples-regtest
USER1=carol
USER2=dave
DATADIR1=${EXAMDIR}/data3
DATADIR2=${EXAMDIR}/data4
TOKENNAME="DemoTokenRegtest"

rm -f \
    ${EXAMDIR}/DemoToken.rgb \
    ${EXAMDIR}/transfer.psbt \
    ${EXAMDIR}/transfer.rgb \
    ${EXAMDIR}/DemoToken-work.yaml
rm -rf \
    ${DATADIR1} \
    ${DATADIR2}
