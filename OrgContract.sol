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

    mapping(uint256 => Document) public documents;
    uint256 public docCount;

    event DocumentUploaded(uint256 docId, address indexed user, string cid, string docType);
    event DocumentVerified(uint256 docId, Status status);

    modifier onlyOrgAdmin() {
        require(msg.sender == orgAdmin, "Only Org Admin");
        _;
    }

    constructor(address _admin, string memory _name) {
        orgAdmin = _admin;
        orgName = _name;
    }

    function uploadDocument(string memory _cid, string memory _docType) external {
        documents[docCount] = Document({
            cid: _cid,
            docType: _docType,
            uploadedBy: msg.sender,
            status: Status.Pending,
            uploadedAt: block.timestamp
        });

        emit DocumentUploaded(docCount, msg.sender, _cid, _docType);
        docCount++;
    }

    function verifyDocument(uint256 _docId, bool approve) external onlyOrgAdmin {
        require(_docId < docCount, "Invalid Doc ID");
        documents[_docId].status = approve ? Status.Approved : Status.Rejected;
        emit DocumentVerified(_docId, documents[_docId].status);
    }

    function getDocument(uint256 _docId) external view returns (Document memory) {
        return documents[_docId];
    }

    function getDocumentCID(uint256 _docId) external view returns (string memory) {
        require(documents[_docId].status == Status.Approved, "Not verified");
        return documents[_docId].cid;
    }
}
