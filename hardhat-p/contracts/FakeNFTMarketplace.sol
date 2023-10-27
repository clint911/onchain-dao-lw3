// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FakeNFTMarketplace {
    /*
     * @Dev Maintain a mapping of fake TokenId to Owner Address
     */
    mapping(uint256 => address) public tokens;
    /*
     * @Dev Set the purchase price for each fake NFT
     */
    uint256 nftPrice = 0.1 ether;

    /*
     * @Dev purchase() accepts ETH and marks the owner of the given tokenId as the caller address
     * @Param _tokenId - the fake NFT tokenId to purchase
     */
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT consts 0.1 ether");
        tokens[_tokenId] = msg.sender;
    }

    /*
     *@Dev getPrice() returns the price of one NFT
     */
    function getPrice() public view returns (uint256) {
        return nftPrice;
    }

    /*
      *@Dev checks whether the given tokenId has already been sold or not
      @Param _tokenId - the tokenId to check for
      */
    function available(uint256 _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}
