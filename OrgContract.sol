// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrgContract {
    address public orgAdmin;
    string public orgName;

    enum Status { Pending, Approved, Rejected }

    struct Document {
        string cid;
        string docType;
        address uploadedBy;
        Status status;
        uint256 uploadedAt;
    }

    // user => their documents
    mapping(address => Document[]) public documentsByUser;

    // unique list of users
    address[] public users;

    // used to track unique users
    mapping(address => bool) public isUserKnown;

    event DocumentUploaded(address indexed user, string cid, string docType);
    event DocumentVerified(address indexed user, uint256 index, Status status);

    modifier onlyOrgAdmin() {
        require(msg.sender == orgAdmin, "Only Org Admin");
        _;
    }

    constructor(address _admin, string memory _name) {
        orgAdmin = _admin;
        orgName = _name;
    }

    function uploadDocument(string memory _cid, string memory _docType) external {
        documentsByUser[msg.sender].push(Document({
            cid: _cid,
            docType: _docType,
            uploadedBy: msg.sender,
            status: Status.Pending,
            uploadedAt: block.timestamp
        }));

        if (!isUserKnown[msg.sender]) {
            users.push(msg.sender);
            isUserKnown[msg.sender] = true;
        }

        emit DocumentUploaded(msg.sender, _cid, _docType);
    }

    function verifyDocument(address user, uint256 index, bool approve) external onlyOrgAdmin {
        require(index < documentsByUser[user].length, "Invalid index");
        documentsByUser[user][index].status = approve ? Status.Approved : Status.Rejected;
        emit DocumentVerified(user, index, documentsByUser[user][index].status);
    }

    function getDocument(address user, uint256 index) external view returns (Document memory) {
        require(index < documentsByUser[user].length, "Invalid index");
        return documentsByUser[user][index];
    }

    function getAllDocuments(address user) external view returns (Document[] memory) {
        return documentsByUser[user];
    }

    function getAllUsers() external view returns (address[] memory) {
        return users;
    }

    function getApprovedDocuments(address user) external view returns (Document[] memory) {
        Document[] memory all = documentsByUser[user];
        uint256 count;

        for (uint256 i = 0; i < all.length; i++) {
            if (all[i].status == Status.Approved) {
                count++;
            }
        }

        Document[] memory approved = new Document[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < all.length; i++) {
            if (all[i].status == Status.Approved) {
                approved[j++] = all[i];
            }
        }

        return approved;
    }
}
