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

    fallback () external payable onlyListed {
        require(msg.value != 0);
        getToken(msg.value, msg.sender);
    }

    function getToken(uint256 _ethsend, address _sender) internal {
        uint8 _multiplicator = 10 * allowListed[_sender]; // allowListed[msg.sender] = tier level = 1 or 2 or 3 (3 is the highest)
        _mint(msg.sender, _ethsend*_multiplicator); // mint for the sender 10 * tierLevel OFA token for every Ether send to the contract
    }


    function addCustomer(address _address, uint8 _tier) public onlyAdmin {
        require(_tier == 1 || _tier == 2 || _tier == 3 || _tier == 0);
        allowListed[_address] = _tier;
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
