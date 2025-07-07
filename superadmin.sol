// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OrgContract.sol";


contract SuperAdmin {
    address public owner;

    struct OrgInfo {
        address orgContractAddress;
        string orgName;
    }

    mapping(address => OrgInfo) public orgs;
    address[] public allOrgs;

    event OrgCreated(address indexed orgAdmin, address contractAddress, string orgName);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Super Admin allowed");
        _;
    }

    function createOrganization(address orgAdmin, string memory orgName) external onlyOwner {
        require(orgAdmin  != address(0), "nota zero address");
        OrgContract newOrg = new OrgContract(orgAdmin, orgName);
        orgs[orgAdmin] = OrgInfo(address(newOrg), orgName);
        allOrgs.push(address(newOrg));
        emit OrgCreated(orgAdmin, address(newOrg), orgName);
    }

    function getAllOrgs() external view returns (address[] memory) {
        return allOrgs;
    }
}
