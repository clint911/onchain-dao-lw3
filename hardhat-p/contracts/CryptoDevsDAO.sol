// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *@notice Interfaces for the NFT Markeplace
 */
interface IFakeNFTMarketplace {
    /**
     * @dev getPrice() returns price of the NFT from the fake Markeplace
     * @return Returns the price in wei for an NFT
     */
    function getPrice() external view returns (uint256);

    /**
     * @dev available checks whether or not a given _tokenId has already been purchased
     * @return Returns true if available, false if not available(already purchased)
     */
    function available() external view returns (bool);

    /**
     * @dev purchase() buys an NFT from our FakeNFTMarketPlace
     * @param _tokenId  - Fake NFT tokenId to purchase
     **/
    function purchase(uint256 _tokenId) external payable;
}

interface ICryptoDevsNFT {
    /**
     * @dev balanceOf() returns no of NFTs owned by a particular address
     * @param owner - address to fetch no of NFTs belonging type
     * @return Returns no of NFTs owned
     **/
    function balanceOf(address owner) external view returns (uint256);

    /**
     *@dev tokenOfOwnerByIndex() returns a tokenId at  a given index for the owner
     *@param owner - address to fetch tokenId for
     *@param index - index of NFT in owned tokens array to fetch
     *@return Returns the TokenId of the NFT
     **/
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);
}

contract CryptoDevsDAO is Ownable {
    /** ___functionality__
     * -> store created proposals in the contract, Allow holders of CryptoDevsNFT to create new proposals and vote on other proposals, allow holders execute a proposal after deadline passed if proposal passed
     *@notice struct named proposal that contains all relevant information
     */
    struct Proposal {
        uint256 nftTokenId; //tokenId of the NFT to purchase from Markeplace if Proposal passes
        uint256 deadline; //UNIX timestamp until which this proposal is active, proposal can be executed after the deadline has passed
        uint256 yayVotes; //no of yay votes for this proposal
        uint256 nayVotes; //no of nay votes for this proposal
        bool executed; //whether or not this proposal has been executed or not, Cannot be executed before deadline has been executed
        mapping(uint256 => bool) voters; //mapping of CryptoDevsNFT tokenId to booleans indicating whether the NFT has already been used to vote or not
    }
    //mapping of proposaIds to proposals to hold all created proposals and a counter to count the number of proposals that exist
    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals; //no of proposals that have been created
    //since we will now be calling functions on  FakeNFTMarketPlace and CryptoDevsNFT, creating variables to store the contracts
    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    /**
     * creating a payable constructor which initializes the contract instances for the NFT Markeplace & cryptoDevsNFT
     * The payable constructor allows this contract to accept an eth deposit when it is being deployed
     **/
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    /**
      @dev creating a modifier which allows a function to be called by someone who owns at least one cryptoDevs NFT
    **/
    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    /**
     * @dev createProposal() allows holder to create a proposal
     * @param _nftTokenId  tokenId of the NFT to be purchased from the fake Markeplace if Proposal passes
     * @return Returns Proposal index for the newly created proposal
     **/
    function createProposal(
        uint256 _nftTokenId
    ) external nftHolderOnly returns (uint256) {
        //you are supposed to pass _nftTokenId inside of available but yk lets see if it works without it
        require(nftMarketplace.available(), "NFT_not_for_sale");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        /**
         * @notice set the proposal voting deadline to be current proposal + 5 minutes, this can be adjusted later to allow for proper analysis and verification of the information provided about the proposal
         **/
        proposal.deadline = block.timestamp + 5 minutes;
        numProposals++;
        return numProposals - 1;
    }

    /**
     * @dev modifier to restrict that proposal being voted on must not have exceeded its deadline
     **/
    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }
    //enum containing the two possible
    enum Vote {
        YAY,
        NAY
    }

    /**
     * @dev voteOnProposal() allows holder to cast vote on active proposal
     * @param proposalIndex - index of proposal to vote in on proposals array
     * @param vote - type of vote they want to cast
     **/
    function voteOnProposal(
        uint256 proposalIndex,
        Vote vote
    ) external nftHolderOnly activeProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];
        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;
        /**
         * @notice calculate how many nfts are owned by the voter that haven't already been used for voting on this proposal
         **/
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");
        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    /**
     *  @notice creating modifier for executing a proposal only whose deadline has expired
     **/
    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    function executeProposal(
        uint256 proposalIndex
    ) external nftHolderOnly inactiveProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];
        /**
         * @notice if the proposal has more YAY votes than NAY votes, make the purchase
         **/
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    /**
     * @dev withdrawEther() allows contract owner (deployer) to withdraw ether from the contract
     **/
    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing_to_withdraw");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "FAILED_TO_WITHDRAW_ETHER");
    }

    /**
     * @dev allowing contract to accept eth without neccessarily calling functions
     **/
    receive() external payable {}

    fallback() external payable {}
}
