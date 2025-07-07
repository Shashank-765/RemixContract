// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OrgContract.sol";

contract SuperAdmin {
    address public owner;

    struct OrgInfo {
        address orgContractAddress;
        string orgName;
        address orgAdmin;
    }

    OrgInfo[] public allOrgs;
    mapping(address => OrgInfo) public orgsByAdmin;

    event OrgCreated(address indexed orgAdmin, address contractAddress, string orgName);
    event AdminFunded(address indexed orgAdmin, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Super Admin allowed");
        _;
    }

    receive() external payable {}

    /// @notice Create new org and fund its admin with 0.1 MATIC
    function createOrganization(address orgAdmin, string memory orgName) external payable onlyOwner {
        require(orgAdmin != address(0), "Invalid admin address");
        require(address(this).balance >= 0.1 ether, "Not enough balance to fund admin");

        OrgContract newOrg = new OrgContract(orgAdmin, orgName);

        OrgInfo memory info = OrgInfo({
            orgContractAddress: address(newOrg),
            orgName: orgName,
            orgAdmin: orgAdmin
        });

        allOrgs.push(info);
        orgsByAdmin[orgAdmin] = info;

        // Send 0.1 MATIC to orgAdmin wallet
        (bool success, ) = orgAdmin.call{value: 0.1 ether}("");
        require(success, "Funding admin failed");

        emit OrgCreated(orgAdmin, address(newOrg), orgName);
        emit AdminFunded(orgAdmin, 0.1 ether);
    }

    /// @notice Return all org info
    function getAllOrgs() external view returns (OrgInfo[] memory) {
        return allOrgs;
    }

    /// @notice Get MATIC balances of all org admins
    function getAllOrgAdminBalances() external view returns (address[] memory admins, uint256[] memory balances) {
        uint256 len = allOrgs.length;
        admins = new address[](len);
        balances = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            admins[i] = allOrgs[i].orgAdmin;
            balances[i] = allOrgs[i].orgAdmin.balance;
        }
    }

    /// @notice Fund a specific org admin manually
    function fundOrgAdmin(address payable orgAdmin, uint256 amount) external onlyOwner {
        require(orgAdmin != address(0), "Invalid address");
        require(address(this).balance >= amount, "Insufficient contract balance");

        (bool sent, ) = orgAdmin.call{value: amount}("");
        require(sent, "Transfer failed");

        emit AdminFunded(orgAdmin, amount);
    }

    /// @notice Check contract balance
    function getSuperAdminBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
