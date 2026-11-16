// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VotingManagementSystem {

    struct Candidate {
        uint candidate_id;
        string name;
        uint voteCount;
    }

    struct Voter {
        uint voter_id;
        string name;
        bool has_voted;
        address wallet;
    }

    struct Transaction {
        uint voter_id;
        uint candidate_id;
        uint timestamp;
    }

    struct Block {
        uint blockNumber;
        uint timestamp;
        uint firstTransactionIndex;
        uint transactionCount;
        bytes32 previousHash;
        bytes32 blockHash;
    }

    address public admin;

    Candidate[] public candidates;
    Transaction[] public transactions;
    Block[] public blockchain;

    mapping(uint => Voter) public voters;
    mapping(uint => bool) public voterExists;
    mapping(uint => bool) public candidateExists;
    mapping(address => uint) public voterWalletId;
    mapping(address => bool) public walletRegistered;

    uint public committedTransactionCount;

    event CandidateAdded(uint candidateId, string name);
    event VoterAdded(uint voterId, string name, address wallet);
    event VoteCast(uint voterId, uint candidateId);
    event BlockCreated(uint blockNumber, bytes32 blockHash);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
        _;
    }

    constructor() {
        admin = msg.sender;

        bytes32 genesisHash = keccak256(
            abi.encodePacked(
                uint(0),
                block.timestamp,
                uint(0),
                uint(0),
                bytes32(0),
                bytes32(0)
            )
        );

        blockchain.push(
            Block(
                0,
                block.timestamp,
                0,
                0,
                bytes32(0),
                genesisHash
            )
        );
    }

    // 1. Add Candidate

    function addCandidate(
        uint _candidateId,
        string memory _name
    ) public onlyAdmin {

        require(!candidateExists[_candidateId],
            "Candidate already exists");

        require(bytes(_name).length > 0,
            "Name cannot be empty");

        candidates.push(
            Candidate(_candidateId, _name, 0)
        );

        candidateExists[_candidateId] = true;

        emit CandidateAdded(_candidateId, _name);
    }

    // 2. Add Voter

    function addVoter(
        uint _voterId,
        string memory _name,
        address _wallet
    ) public onlyAdmin {

        require(!voterExists[_voterId],
            "Voter ID already exists");

        require(_wallet != address(0),
            "Invalid wallet");

        require(!walletRegistered[_wallet],
            "Wallet already registered");

        require(bytes(_name).length > 0,
            "Name cannot be empty");

        voters[_voterId] = Voter(
            _voterId,
            _name,
            false,
            _wallet
        );

        voterExists[_voterId] = true;
        walletRegistered[_wallet] = true;
        voterWalletId[_wallet] = _voterId;

        emit VoterAdded(_voterId, _name, _wallet);
    }

    // 3. Cast Vote

    function castVote(uint _candidateId) public {

        require(walletRegistered[msg.sender],
            "You are not registered");

        uint voterId = voterWalletId[msg.sender];

        require(!voters[voterId].has_voted,
            "You have already voted");

        require(candidateExists[_candidateId],
            "Candidate does not exist");

        voters[voterId].has_voted = true;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].candidate_id == _candidateId) {
                candidates[i].voteCount++;
                break;
            }
        }

        transactions.push(
            Transaction(
                voterId,
                _candidateId,
                block.timestamp
            )
        );

        emit VoteCast(voterId, _candidateId);
    }

    // Calculate block hash using its actual transactions
    
    function calculateHash(
        uint _blockNumber,
        uint _timestamp,
        uint _firstIndex,
        uint _count,
        bytes32 _previousHash
    ) internal view returns (bytes32) {

        bytes32 transactionHash = bytes32(0);

        for (
            uint i = _firstIndex;
            i < _firstIndex + _count;
            i++
        ) {
            Transaction storage t = transactions[i];

            transactionHash = keccak256(
                abi.encodePacked(
                    transactionHash,
                    t.voter_id,
                    t.candidate_id,
                    t.timestamp
                )
            );
        }

        return keccak256(
            abi.encodePacked(
                _blockNumber,
                _timestamp,
                _firstIndex,
                _count,
                _previousHash,
                transactionHash
            )
        );
    }

    // 4. Create Block
    function createBlock() public onlyAdmin {

        uint count = transactions.length -
            committedTransactionCount;

        require(count > 0, "No new transactions");

        uint number = blockchain.length;

        uint timestamp = block.timestamp;

        bytes32 previousHash =
            blockchain[number - 1].blockHash;

        uint firstIndex = committedTransactionCount;

        bytes32 newHash = calculateHash(
            number,
            timestamp,
            firstIndex,
            count,
            previousHash
        );

        blockchain.push(
            Block(
                number,
                timestamp,
                firstIndex,
                count,
                previousHash,
                newHash
            )
        );

        committedTransactionCount = transactions.length;

        emit BlockCreated(number, newHash);
    }

    // 5. Print Blockchain: Get Block
    function getBlock(uint _index)
        public view
        returns (
            uint,
            uint,
            uint,
            uint,
            bytes32,
            bytes32
        )
    {
        require(_index < blockchain.length,
            "Invalid block");

        Block storage b = blockchain[_index];

        return (
            b.blockNumber,
            b.timestamp,
            b.firstTransactionIndex,
            b.transactionCount,
            b.previousHash,
            b.blockHash
        );
    }

    // Get Blockchain Length
    function getBlockchainLength()
        public view returns (uint)
    {
        return blockchain.length;
    }

    // Get Transaction
    function getTransaction(uint _index)
        public view
        returns (uint, uint, uint)
    {
        require(_index < transactions.length,
            "Invalid transaction");

        Transaction storage t = transactions[_index];

        return (
            t.voter_id,
            t.candidate_id,
            t.timestamp
        );
    }

    // 6. Validate Blockchain
    function validateChain()
        public view returns (bool)
    {
        if (blockchain.length == 0) {
            return false;
        }

        uint expectedFirstIndex = 0;

        for (uint i = 0; i < blockchain.length; i++) {

            Block storage b = blockchain[i];

            if (b.blockNumber != i) {
                return false;
            }

            if (b.firstTransactionIndex != expectedFirstIndex) {
                return false;
            }

            if (
                b.firstTransactionIndex + b.transactionCount >
                committedTransactionCount
            ) {
                return false;
            }

            if (i == 0) {
                if (b.previousHash != bytes32(0)) {
                    return false;
                }
            } else {
                if (
                    b.previousHash != blockchain[i - 1].blockHash
                ) {
                    return false;
                }
            }

            bytes32 calculatedHash = calculateHash(
                b.blockNumber,
                b.timestamp,
                b.firstTransactionIndex,
                b.transactionCount,
                b.previousHash
            );

            if (calculatedHash != b.blockHash) {
                return false;
            }

            expectedFirstIndex += b.transactionCount;
        }

        if (expectedFirstIndex != committedTransactionCount) {
            return false;
        }

        return true;
    }

    // Get Candidate Details
    function getCandidate(uint _index)
        public view
        returns (uint, string memory, uint)
    {
        require(_index < candidates.length,
            "Invalid candidate");

        Candidate storage c = candidates[_index];

        return (
            c.candidate_id,
            c.name,
            c.voteCount
        );
    }

    function getCandidateCount()
        public view returns (uint)
    {
        return candidates.length;
    }

    // Get Voter Details
    function getVoter(uint _voterId)
        public view
        returns (uint, string memory, bool, address)
    {
        require(voterExists[_voterId],
            "Voter does not exist");

        Voter storage v = voters[_voterId];

        return (
            v.voter_id,
            v.name,
            v.has_voted,
            v.wallet
        );
    }

    function getTransactionCount()
        public view returns (uint)
    {
        return transactions.length;
    }
}
