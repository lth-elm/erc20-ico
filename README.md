1. [Presentation](#presentation)
2. [Functions and code review](#function)
3. [Migration](#migration)
    1. [To Ganache](#ganache)
    2. [To Rinkeby testnet](#rinkeby)
        1. [HDWalletProvider](#hdwalletprovider)
        2. [Infura](#infura)
        3. [Setting up a Truffle project](#truffleproject)
        4. [Deploying the contract](#deployment)
3. [Manipulation on the Rinkeby testnet](#manipulation)

# Presentation <a name="presentation"></a>

This very simple smart contract written on a single [file](contracts/OFAToken.sol) simulates the ICO (Initial Coin Offering) of the **OneForAll (OFA)** token based on the **ERC20** standard.

The installation of the openzeppelin library ```npm install @openzeppelin/contracts```, simplifies the development of smart-contracts thanks to the integration of ERC standards and their direct use.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OFAToken is ERC20 {

    address owner;
    uint8 initdecimals = 18; // same as default erc20 (eth)

    // uint256 initSupply = 1400 * 10^initdecimals;

    constructor() ERC20("OneForAll", "OFA") {
        owner = msg.sender;
        _setupDecimals(initdecimals); // not required since it's the same as the default
        
        // _mint(address(this), initSupply);
    }
}
```

Thanks to the import of the *ERC20.sol* file from the openzeppelin library we were able to create in only a few lines our first contract that generates OneForAll tokens with 'OFA' as its ticker. 

For ease of use the decimals number has been kept at 18 as it would have been by default if the line ```_setupDecimals(initdecimals);``` had not been entered.

Finally, the *total supply* can be minted directly in the contract before being redistributed but our approach will be to mint it directly in the address that will have sent us ether if and only if this address belongs to our **whitelist**.


# Functions and code review <a name="function"></a>

Our intention is to launch an ICO which will be accessible to only a few addresses.

Every address that belongs to the whitelist *allowListed* must be given a tier level (1 to 3) that will grant it more or less OFAs, with tier 3 being the most important. This data is stored in a mapping made public ```mapping(address => uint8) public allowListed;```.

We write a ```modifier onlyAdmin``` that verifies whether a function call is made from the address that deployed the contract or not, indeed, functions such as ```function addCustomer(address _address, uint8 _tier) public onlyAdmin``` that would add an address and a tier level in *allowListed* must not be executed by anyone other than the administrator.

```solidity
mapping(address => uint8) public allowListed; // uint for tier 1, 2 or 3

function addCustomer(address _address, uint8 _tier) public onlyAdmin {
    require(_tier == 1 || _tier == 2 || _tier == 3 || _tier == 0);
    allowListed[_address] = _tier;
}

modifier onlyAdmin () {
    require(msg.sender == owner);
    _;
}
```

---

Before sending OFAs we have to make sure that we receive ETH, the function ```fallback () external payable onlyListed``` will be executed when the contract receives Ether. As before, the ```onlyListed``` modifier checks that the address sending Ether does belongs to *allowListed*, otherwise they will not be able to send Ether to the contract nor receive OFA.

The function ```getToken(uint256 _ethsend, address _sender) internal``` called from within the fallback will then mint to this address 10 x [tier level] x [number of eth sent to the contract] OneForAll tokens.

```solidity
fallback () external payable onlyListed {
    require(msg.value != 0);
    getToken(msg.value, msg.sender);
}

function getToken(uint256 _ethsend, address _sender) internal {
    uint8 _multiplicator = 10 * allowListed[_sender]; // allowListed[msg.sender] = tier level = 1 or 2 or 3
    _mint(msg.sender, _ethsend*_multiplicator);
}

modifier onlyListed () {
    require(allowListed[msg.sender] != 0);
    _;
}
```

# Migration <a name="migration"></a>

## To Ganache <a name="ganache"></a>

The migration to **Ganache** is really easy thanks to **Truffle** which has been initialized at the beginning of the project and lets us write, compile and deploy smart contracts through an integrated environment.

Run an Ethereum workspace on ganache and identify the *RPC Server* presumably on HTTP://127.0.0.1:7545.

Fill in the file [truffle-config.js](truffle-config.js)

```js
module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // can be replaced by Ganache network id
    }
  }
};
```

Then type in the console :
```
truffle migrate
```

We can notice that the first address has been credited because it is the one used to deploy the contract by default. Under the tab 'BLOCKS' 4 blocks have been added and the transactions are shown under the tab 'TRANSACTIONS'.

![Ganache](./README_images/ganache.PNG "Ganache")

It is then possible with the truffle console to interact with the contract for testing.

```
truffle console
```
```
truffle(development)>
```

## To Rinkeby testnet <a name="rinkeby"></a>

### HDWalletProvider <a name="hdwalletprovider"></a>

In order to migrate to a testnet we need HDWalletProvider from truffle: ```npm install @truffle/hdwallet-provider```.

### Infura <a name="infura"></a>

It is also necessary to register to **Infura** which is an infrastructure allowing Dapps developers *'decentralized applications'* to access information of the Ethereum blockchain without owning a full node. Once registered, you have to create a project, select an *endpoint* (testnet Rinkeby for instance) and get the API key or *Project ID* and the first part of the https address.

![infura-keys](./README_images/infuraKey.PNG "Infura Keys")

### Setting up a Truffle project <a name="truffleproject"></a>

The following lines in the file [truffle-config.js](truffle-config.js) define the HDWalletProvider object and enables the use of the dotenv module.

```js
const HDWalletProvider = require('@truffle/hdwallet-provider');
require('dotenv').config()

const mnemonic = process.env.MNENOMIC
const infuraKey = process.env.INFURA_API_KEY
```

At the root of the project in a ```.env``` file write in the project ID we've previously retrieved as well as the address seed of the address deploying the contract (which will therefore become the admin).

```
MNENOMIC = "orange apple banana ..."
INFURA_API_KEY = <INFURA_PROJECT_ID>
```

Then we set the network we want to deploy to : 

```js
module.exports = {
  networks: {
    rinkeby: {
      provider: () => new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/" + infuraKey, 1), // second account generated by the mnemonic (index 1)
      network_id: 4, // Rinkeby's id
      gas: 4500000,
      gasPrice: 10000000000,
    },
```

*If we want to use another address than the first one generated by the seed, we can specify its index in the parameter of ```HDWalletProvider()```.*

### Deploying the contract <a name="deployment"></a>

Build the project.

```
truffle compile
```

Then deploy to the chosen network.

```
truffle migrate --network rinkeby
```

The following response should be displayed by the console :

```
Starting migrations...
======================
> Network name:    'rinkeby'
> Network id:      4
> Block gas limit: 10000000 (0x989680)


1_initial_migration.js
======================

   Deploying 'Migrations'
   ----------------------
   > transaction hash:    0x2ef9d24da6c6b1501b69f19f0f9732ed5cf5959b318848e8cf131aef13227c25
   > Blocks: 0            Seconds: 12
   > contract address:    0xd5Df66C27FF5Bd53Cc48fEAC832984EFDC993da0
   > block number:        8244084
   > block timestamp:     1615894442
   > account:             0xc80E625d5a29d8d377D360ba9c0fd2Cded049F94
   > balance:             8.049068485
   > gas used:            186951 (0x2da47)
   > gas price:           10 gwei
   > value sent:          0 ETH
   > total cost:          0.00186951 ETH


   > Saving migration to chain.
   > Saving artifacts
   -------------------------------------
   > Total cost:          0.00186951 ETH


2_deploy_contract.js
====================

   Deploying 'OFAToken'
   --------------------
   > transaction hash:    0xaf3c0daaed553adf6cfe9ce85408b76f01b88bf6a6dfed4b6569ddda7ff56a35
   > Blocks: 1            Seconds: 12
   > contract address:    0xcD30CDAfBB3FC9cDb6e12Fa725F7659749ED79cf
   > block number:        8244086
   > block timestamp:     1615894472
   > account:             0xc80E625d5a29d8d377D360ba9c0fd2Cded049F94
   > balance:             8.035203895
   > gas used:            1344124 (0x14827c)
   > gas price:           10 gwei
   > value sent:          0 ETH
   > total cost:          0.01344124 ETH


   > Saving migration to chain.
   > Saving artifacts
   -------------------------------------
   > Total cost:          0.01344124 ETH


Summary
=======
> Total deployments:   2
> Final cost:          0.01531075 ETH
```

The transaction hash is *0xaf3c0daaed553adf6cfe9ce85408b76f01b88bf6a6dfed4b6569ddda7ff56a35* viewable at this [address](https://rinkeby.etherscan.io/tx/0xaf3c0daaed553adf6cfe9ce85408b76f01b88bf6a6dfed4b6569ddda7ff56a35), and the OFAToken contract address ***0xcD30CDAfBB3FC9cDb6e12Fa725F7659749ED79cf*** is viewable [here](https://rinkeby.etherscan.io/address/0xcd30cdafbb3fc9cdb6e12fa725f7659749ed79cf).

# Manipulation on the Rinkeby testnet <a name="manipulation"></a>

If you are not registered on the whitelist you will not be able to receive OFA's, you have to send me first your erc20 address so that I can add you (you can try to do it yourself but you will see that you don't have the authorization).

With [mycrypto.com](https://app.mycrypto.com/interact-with-contracts) you can interact with the contract by providing its address and [ABI](./build/contracts/OFAToken.json), and by entering your personal address in the 'allowListed' function you can view what tier level were assigned to you.

![allowListedInteraction](./README_images/readAllowListed.PNG "Interact with allowListed")

---

If your tier level is different than '0' then you can receive OneForAll tokens at this address by sending Ether to the contract.

![metamaskOFA](./README_images/metamaskOFA.PNG "OFA token in metamask")

\* *As a reminder, you will receive 10 x [tier level] x [eth sent] OFA tokens.*