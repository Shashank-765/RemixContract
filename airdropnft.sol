// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract MultiNFTAirdrop {
    address public owner;

    struct AirdropInfo {
        address recipient;
        address nftContract;
        uint256 tokenId;
    }

    mapping(address => bool) public hasClaimed;

    mapping(address => AirdropInfo) public userAirdrops;

    AirdropInfo[] public allAirdrops;
    event AirdropEvent(address indexed nftContract, address recipient, uint256 tokenId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }


    constructor() {
        owner = msg.sender;
    }

    function airdrop (
        address nftContract,
        address recipient,
        uint256 tokenId
    )external onlyOwner{
        require(address(nftContract) != address(0), "Invalid NFT contract address");
        require(recipient != address(0), "Invalid recipient");
        require(!hasClaimed[recipient], "Already airdropped");
        
        hasClaimed[recipient] = true; 

        AirdropInfo memory info = AirdropInfo({
            recipient: recipient,
            nftContract: nftContract,
            tokenId: tokenId
        });

        userAirdrops[recipient] = info;
        allAirdrops.push(info);

        IERC721(nftContract).safeTransferFrom(msg.sender, recipient, tokenId);

        emit AirdropEvent(nftContract, recipient, tokenId);


    }

    function bulkAirdrop(
        address[] calldata nftContracts,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        require(
            nftContracts.length == recipients.length && 
            recipients.length == tokenIds.length,
            "Array lengths mismatch"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];

            if (hasClaimed[recipient]) {
                continue; 
            }

            hasClaimed[recipient] = true;

            AirdropInfo memory info = AirdropInfo({
                recipient: recipient,
                nftContract: nftContracts[i],
                tokenId: tokenIds[i]
            });

            userAirdrops[recipient] = info;
            allAirdrops.push(info);

            IERC721(nftContracts[i]).safeTransferFrom(
                msg.sender,
                recipient,
                tokenIds[i]
            );
            emit AirdropEvent(nftContracts[i], recipient, tokenIds[i]);

        }
    }

    function getUserAirdrop(address user) external view returns (address, uint256) {
        AirdropInfo memory info = userAirdrops[user];
        return (info.nftContract, info.tokenId);
    }

    function getAllAirdrops(uint256 offset, uint256 limit, bool isAll) external view returns (AirdropInfo[] memory) {
        uint256 end = offset + limit;
        if (end > allAirdrops.length) {
            end = allAirdrops.length;
        }
    if(!isAll){

        AirdropInfo[] memory result = new AirdropInfo[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = allAirdrops[i];
        }

        return result;
    }else{
        return allAirdrops;
    }
    }

    function totalAirdropped() external view returns (uint256) {
        return allAirdrops.length;
    }

    function resetClaim(address user) external onlyOwner {
        hasClaimed[user] = false;
        delete userAirdrops[user];
    }

    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}


