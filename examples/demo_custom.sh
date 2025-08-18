#!/usr/bin/env bash

set -xe

cargo build --workspace --all-targets
export RUST_BACKTRACE=1
RGB="./target/debug/rgb -d examples/data"
RGB_2="./target/debug/rgb -d examples/data2"

rm -f \
    examples/data/bitcoin.testnet/*.issuer \
    examples/DemoToken.rgb \
    examples/transfer.psbt \
    examples/transfer.rgb \
    examples/transfer.pfab \
    examples/Transfer.yaml
rm -rf \
    examples/data/bitcoin.testnet/DemoToken.*.contract \
    examples/data2/bitcoin.testnet/DemoToken.*.contract

$RGB init
$RGB_2 init

# RGB20-FNA
# https://github.com/pandora-prime/rgb-issuers/blob/49b4048cdffb93fd84161713891d3d8fa02f7eaf/compiled/RGB20-Simplest-v0-AYkSrg.issuer
$RGB import examples/RGB20-FNA.issuer
$RGB issue -w alice examples/DemoToken.yaml
$RGB backup DemoToken examples/DemoToken.rgb
$RGB_2 accept -w bob -u examples/DemoToken.rgb

$RGB contracts
$RGB state -go -w alice
$RGB_2 contracts
$RGB_2 state -go -w bob

AUTH_TOKEN=$($RGB_2 invoice -w bob --nonce 0 --seal-only DemoToken)
INVOICE=$($RGB_2 invoice -w bob --nonce 0 DemoToken 10)
$RGB script -w alice "$INVOICE" examples/Transfer.yaml --esplora
$RGB exec -w alice examples/Transfer.yaml examples/transfer.pfab 1000 examples/transfer.psbt
$RGB complete -w alice examples/transfer.pfab examples/transfer.psbt
$RGB consign DemoToken -t "$AUTH_TOKEN" examples/transfer.rgb
$RGB_2 accept -w bob examples/transfer.rgb

$RGB state -goa -w alice --sync --mempool
$RGB_2 state -go -w bob --sync --mempool
