# Présentation

Ce smart contract très simple et sur un seul [fichier](contracts/OFAToken.sol) simule l'ICO (Initial Coin Offering) du token **OneForAll (OFA)** issus du standard **ERC20**.

L'installation de la librairie openzeppelin ```npm install @openzeppelin/contracts```, permet de simplifier le développement des smart-contracts grâce à l'intégration des standards ERC et leur utilisation direct.

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

Grâce à l'import du fichier *ERC20.sol* de la librairie d'openzeppelin on a pu en quelque ligne créer notre premier contrat générant des tokens OneForAll dont le ticker est 'OFA'. 

Par simplicité le nombre de décimal a été maintenu à 18 tel qu'il l'aurait été par défaut si la ligne ```_setupDecimals(initdecimals);``` n'aurait pas été entré.

Enfin, concernant la *total supply* celle ci peut être 'minter' créer directement dans le contrat avant d'être redistribué mais notre approche sera de la minter directement dans l'adresse qui nous aura envoyée de l'ether si et seulement si cette adresse appartient à notre **whitelist**.


# Fonctions et revue de code

Notre objectif est de lancer une ICO auquelle auront accès seulement quelques adresses.

Chaque adresse appartenant à la whitelist *allowListed* doit être associée à un niveau de tier (1 à 3) qui lui permettra de recevoir plus ou moins d'OFA, le tier 3 étant le plus important. On enregistre ces données dans un mapping rendu public ```mapping(address => uint8) public allowListed;```.

On écrit un ```modifier onlyAdmin``` qui permet de vérifier qu'un appel de fonction est faite depuis l'adresse ayant déployé le contrat, en effet, la fonction suivante ```function addCustomer(address _address, uint8 _tier) public onlyAdmin``` permettant d'ajouter une adresse et un niveau de tier dans *allowListed* ne doit pas pouvoir être exécuté par n'importe qui. 

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

Avant d'envoyer des OFA on doit s'assurer de bien recevoir des ETH, la fonction ```fallback () external payable onlyListed``` sera exécutée quand le contrat recevra des Ethers. De la même manière que précedemment le modifier ```onlyListed``` vérifie que l'adresse envoyant des Ether appartient bien à *allowListed* auquel cas il ne pourra ni envoyer d'Ether au contrat ni recevoir des OFA.

La fonction ```getToken(uint256 _ethsend, address _sender) internal ``` appelé depuis le fallback va alors minter à cette adresse 10 x [niveau de tier] x [nombre d'eth envoyé au contrat] de tokens OneForAll.

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

# Migration

## Vers Ganache



## Vers testnet Rinkeby