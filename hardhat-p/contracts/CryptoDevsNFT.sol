//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CryptoDevsNFT is ERC721Enumerable {
    /*
     * @Dev initialize ERC721 contract
     */
    constructor() ERC721("CryptoDevs", "CD") {}

    /*
     * @Dev Have a public mint function that anyone can call to get an nft
     */
    function mint() public {
        _safeMint(msg.sender, totalSupply());
    }
}
