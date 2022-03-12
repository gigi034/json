#!/bin/bash
echo "Make sure all files required are in the same folder as this script"
echo ""
read -p 'Mint To Address: ' mintAddr
read -p 'Policy ID:' policyID
read -p 'Policy Script file name:' scriptName
read -p 'Lovelace to Include:' loveLace
read -p 'Enter TX Invalid After Slot (1000 slots into the future is fine): ' nftSlot
read -p 'COMB Number:' combNum
read -p 'Starting Number:' startNum
read -p 'Ending Number:' endNum
echo "Next, enter each of the numbers in this set of 7.."
read -p 'Num1:' numA
read -p 'Num2:' numB
read -p 'Num3:' numC
read -p 'Num4:' numD
read -p 'Num5:' numE
read -p 'Num6:' numF
read -p 'Num7:' numG
nftName="ZEUS"
filePre="ZEUS_COMB"
fileSuf=${combNum}_${startNum}-${endNum}.json
jsonName=${filePre}${fileSuf}
TESTNET_MAGIC_NUM=1097911063

# Get UTxO
cardano-cli query utxo \
    --address ${mintAddr} \
    --testnet-magic ${TESTNET_MAGIC_NUM} > fullUtxo.out
tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out
cat balance.out
tx_in=""
total_balance=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    echo TxHash: ${in_addr}#${idx}
    echo ADA: ${utxo_balance}
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < balance.out
txcnt=$(cat balance.out | wc -l)
echo Total ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}
echo TXIn: ${tx_in}
newbal=$((${total_balance}-${loveLace}))
# Draft the tx
echo cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out ${mintAddr}+${newbal} \
    --tx-out ${mintAddr}+${loveLace}+"1 ${policyID}.${nftName}${numA}"+"1 ${policyID}.${nftName}${numB}"+"1 ${policyID}.${nftName}${numC}"+"1 ${policyID}.${nftName}${numD}"+"1 ${policyID}.${nftName}${numE}"+"1 ${policyID}.${nftName}${numF}"+"1 ${policyID}.${nftName}${numG}" \
    --invalid-hereafter 0 \
    --fee 0 \
    --mint="1 ${policyID}.${nftName}${numA}"+"1 ${policyID}.${nftName}${numB}"+"1 ${policyID}.${nftName}${numC}"+"1 ${policyID}.${nftName}${numD}"+"1 ${policyID}.${nftName}${numE}"+"1 ${policyID}.${nftName}${numF}"+"1 ${policyID}.${nftName}${numG}" \
    --minting-script-file ${scriptName} \
    --metadata-json-file ${jsonName} \
    --alonzo-era \
    --out-file tx_nft.tmp

# Calculate the fee
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file tx_nft.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 2 \
    --witness-count 2 \
    --testnet-magic ${TESTNET_MAGIC_NUM} \
    --protocol-params-file params.json | awk '{ print $1 }')
    
echo fee: $fee
txOut=$((${total_balance}-${fee}-${loveLace}))
echo Change Output: ${txOut}

# Build the TX
echo "=========================="
echo "....Building for: ${tx_in}"
echo "=========================="
echo ""
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out ${mintAddr}+${txOut} \
    --tx-out ${mintAddr}+${loveLace}+"1 ${policyID}.${nftName}${numA}"+"1 ${policyID}.${nftName}${numB}"+"1 ${policyID}.${nftName}${numC}"+"1 ${policyID}.${nftName}${numD}"+"1 ${policyID}.${nftName}${numE}"+"1 ${policyID}.${nftName}${numF}"+"1 ${policyID}.${nftName}${numG}" \
    --invalid-hereafter ${nftSlot} \
    --fee ${fee} \
    --mint="1 ${policyID}.${nftName}${numA}"+"1 ${policyID}.${nftName}${numB}"+"1 ${policyID}.${nftName}${numC}"+"1 ${policyID}.${nftName}${numD}"+"1 ${policyID}.${nftName}${numE}"+"1 ${policyID}.${nftName}${numF}"+"1 ${policyID}.${nftName}${numG}" \
    --minting-script-file ${scriptName} \
    --metadata-json-file ${jsonName} \
    --alonzo-era \
    --out-file tx.raw

echo ""
echo "===== Finished ====="
echo " Raw File for signing: tx.raw"
echo ""
