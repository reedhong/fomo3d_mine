#!/bin/bash

cd flat_contracts 
rm -rf *
cd ..
truffle-flattener contracts/CorpBank.sol >flat_contracts/CorpBankFlat.sol
truffle-flattener contracts/FoMo3Dlong.sol >flat_contracts/FoMo3DlongFlat.sol
truffle-flattener contracts/FundForwarder.sol >flat_contracts/FundForwarderFlat.sol
truffle-flattener contracts/SettingGetter.sol >flat_contracts/SettingGetterFlat.sol
truffle-flattener contracts/PlayerBook.sol >flat_contracts/PlayerBookFlat.sol
truffle-flattener contracts/Team.sol >flat_contracts/TeamFlat.sol
