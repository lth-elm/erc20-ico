// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OFAToken is ERC20 {

    address owner;
    uint8 initdecimals = 18; // same as default erc20 (eth)
    // uint256 initSupply = 1400 * 10^initdecimals;

    mapping(address => uint8) public allowListed; // uint for tier 1, 2 or 3


    constructor() ERC20("OneForAll", "OFA") {
        owner = msg.sender;
        _setupDecimals(initdecimals); // this line is not required since it's the same as the default
        // _mint(address(this), initSupply); // contract address
    }


    function getToken(uint256 ethsend) public onlyListed {
        require(ethsend > 0);

        uint8 multiplicator = 10 * allowListed[msg.sender]; // allowListed[msg.sender] = tier level = 1 or 2 or 3 (3 is the highest)

        transfer(address(this), ethsend); // send ether to the contract address
        _mint(msg.sender, ethsend*multiplicator); // "send" 10*tierLevel OFA token for every Ether send to the contract
    }


    function addCustomer(address adrs, uint8 tier) public onlyAdmin {
        require(tier == 1 || tier == 2 || tier == 3 || tier == 0);
        allowListed[adrs] = tier;
    }


    modifier onlyAdmin () {
        require(msg.sender == owner);
        _;
    }

    modifier onlyListed () {
        require(allowListed[msg.sender] != 0);
        _;
    }
}
