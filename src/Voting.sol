// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract BallotBox {
    // Optimized struct with packed storage
    struct Proposal {
        uint256 id; // slot 1
        address author; // slot 2 (20 bytes)
        uint96 yesVotes; // slot 2 (12 bytes) - packed with author
        uint96 noVotes; // slot 3 (12 bytes)
        uint32 createdAt; // slot 3 (4 bytes) - packed
        uint32 deadline; // slot 3 (4 bytes) - packed
        bool active; // slot 3 (1 byte) - packed
        string title; // slot 4+
        string description; // slot N+
        bytes32 detailsHash; // slot M (32 bytes) - IPFS hash instead of full details
    }

    struct Vote {
        bool hasVoted;
        bool vote; // true = yes, false = no
    }

    // State variables
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Vote)) public votes;
    mapping(address => uint256[]) public proposalsByAuthor; // Gas optimization for author queries
    uint256 public proposalCount;
    uint256 public constant MAX_TITLE_LENGTH = 100;
    uint256 public constant MAX_DESCRIPTION_LENGTH = 200;

    // Events
    event ProposalCreated(
        uint256 indexed proposalId, address indexed author, string title, uint32 deadline, bytes32 detailsHash
    );

    event VoteCast(uint256 indexed proposalId, address indexed voter, bool vote);

    // Errors
    error InvalidDeadline();
    error ProposalNotFound();
    error ProposalExpired();
    error ProposalNotActive();
    error AlreadyVoted();
    error TitleTooLong();
    error DescriptionTooLong();
    error EmptyTitle();
    error EmptyDescription();
    error VoteCountOverflow();

    /**
     * @dev Create a new proposal
     * @param _title The proposal title
     * @param _description Short description of the proposal
     * @param _detailsHash IPFS hash of detailed description (32 bytes)
     * @param _deadline Unix timestamp when voting should end (uint32 for gas optimization)
     */
    function createProposal(
        string calldata _title,
        string calldata _description,
        bytes32 _detailsHash,
        uint32 _deadline
    ) external returns (uint256) {
        // Validate inputs
        if (bytes(_title).length == 0) revert EmptyTitle();
        if (bytes(_description).length == 0) revert EmptyDescription();
        if (bytes(_title).length > MAX_TITLE_LENGTH) revert TitleTooLong();
        if (bytes(_description).length > MAX_DESCRIPTION_LENGTH) revert DescriptionTooLong();
        if (_deadline <= block.timestamp) revert InvalidDeadline();

        // Increment proposal count and use as ID
        unchecked {
            proposalCount++;
        }
        uint256 proposalId = proposalCount;

        // Create new proposal with packed struct
        proposals[proposalId] = Proposal({
            id: proposalId,
            author: msg.sender,
            yesVotes: 0,
            noVotes: 0,
            createdAt: uint32(block.timestamp),
            deadline: _deadline,
            active: true,
            title: _title,
            description: _description,
            detailsHash: _detailsHash
        });

        // Add to author's proposal list for efficient queries
        proposalsByAuthor[msg.sender].push(proposalId);

        emit ProposalCreated(proposalId, msg.sender, _title, _deadline, _detailsHash);
        return proposalId;
    }

    /**
     * @dev Vote on a proposal
     * @param _proposalId The ID of the proposal to vote on
     * @param _vote true for yes, false = no
     */
    function vote(uint256 _proposalId, bool _vote) external {
        Proposal storage proposal = proposals[_proposalId];

        // Validate proposal exists and is active
        if (proposal.id == 0) revert ProposalNotFound();
        if (!proposal.active) revert ProposalNotActive();
        if (block.timestamp > proposal.deadline) revert ProposalExpired();

        // Check if user has already voted
        if (votes[_proposalId][msg.sender].hasVoted) revert AlreadyVoted();

        // Record the vote
        votes[_proposalId][msg.sender] = Vote({hasVoted: true, vote: _vote});

        // Update vote counts with overflow protection
        if (_vote) {
            unchecked {
                if (proposal.yesVotes == type(uint96).max) revert VoteCountOverflow();
                proposal.yesVotes++;
            }
        } else {
            unchecked {
                if (proposal.noVotes == type(uint96).max) revert VoteCountOverflow();
                proposal.noVotes++;
            }
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Get a single proposal by ID
     * @param _proposalId The ID of the proposal
     */
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        if (proposals[_proposalId].id == 0) revert ProposalNotFound();
        return proposals[_proposalId];
    }

    /**
     * @dev Get proposals with pagination (most recent first)
     * @param _offset Number of proposals to skip
     * @param _limit Maximum number of proposals to return
     */
    function getProposals(uint256 _offset, uint256 _limit) external view returns (Proposal[] memory) {
        if (_limit == 0 || _limit > 50) _limit = 50; // Max 50 per page
        if (_offset >= proposalCount) {
            return new Proposal[](0);
        }

        uint256 remaining = proposalCount - _offset;
        uint256 length = remaining < _limit ? remaining : _limit;
        Proposal[] memory result = new Proposal[](length);

        // Return proposals in reverse order (newest first)
        for (uint256 i = 0; i < length; i++) {
            uint256 proposalId = proposalCount - _offset - i;
            result[i] = proposals[proposalId];
        }

        return result;
    }

    /**
     * @dev Get proposals by author with pagination (optimized with indexing)
     * @param _author The author's address
     * @param _offset Number of proposals to skip
     * @param _limit Maximum number of proposals to return
     */
    function getProposalsByAuthor(address _author, uint256 _offset, uint256 _limit)
        external
        view
        returns (Proposal[] memory)
    {
        if (_limit == 0 || _limit > 50) _limit = 50;

        uint256[] memory authorProposalIds = proposalsByAuthor[_author];
        uint256 totalAuthorProposals = authorProposalIds.length;

        if (_offset >= totalAuthorProposals) {
            return new Proposal[](0);
        }

        uint256 remaining = totalAuthorProposals - _offset;
        uint256 length = remaining < _limit ? remaining : _limit;
        Proposal[] memory result = new Proposal[](length);

        // Return proposals in reverse order (newest first)
        for (uint256 i = 0; i < length; i++) {
            uint256 index = totalAuthorProposals - 1 - _offset - i;
            uint256 proposalId = authorProposalIds[index];
            result[i] = proposals[proposalId];
        }

        return result;
    }

    /**
     * @dev Get proposal IDs by author (gas-efficient alternative)
     * @param _author The author's address
     */
    function getProposalIdsByAuthor(address _author) external view returns (uint256[] memory) {
        return proposalsByAuthor[_author];
    }

    /**
     * @dev Get open proposals with pagination (most recent first)
     * @param _offset Number of proposals to skip
     * @param _limit Maximum number of proposals to return
     */
    function getOpenProposals(uint256 _offset, uint256 _limit) external view returns (Proposal[] memory) {
        if (_limit == 0 || _limit > 50) _limit = 50;

        uint256 found = 0;
        uint256 skipped = 0;
        Proposal[] memory result = new Proposal[](_limit);

        // Iterate through proposals from newest to oldest
        for (uint256 i = proposalCount; i > 0 && found < _limit; i--) {
            Proposal storage proposal = proposals[i];

            // Check if proposal is open (active and not expired)
            if (proposal.active && block.timestamp <= proposal.deadline) {
                if (skipped >= _offset) {
                    result[found] = proposal;
                    found++;
                } else {
                    skipped++;
                }
            }
        }

        // Resize array to actual found count
        assembly {
            mstore(result, found)
        }

        return result;
    }

    /**
     * @dev Get closed proposals with pagination (most recent first)
     * @param _offset Number of proposals to skip
     * @param _limit Maximum number of proposals to return
     */
    function getClosedProposals(uint256 _offset, uint256 _limit) external view returns (Proposal[] memory) {
        if (_limit == 0 || _limit > 50) _limit = 50;

        uint256 found = 0;
        uint256 skipped = 0;
        Proposal[] memory result = new Proposal[](_limit);

        // Iterate through proposals from newest to oldest
        for (uint256 i = proposalCount; i > 0 && found < _limit; i--) {
            Proposal storage proposal = proposals[i];

            // Check if proposal is closed (inactive or expired)
            if (!proposal.active || block.timestamp > proposal.deadline) {
                if (skipped >= _offset) {
                    result[found] = proposal;
                    found++;
                } else {
                    skipped++;
                }
            }
        }

        // Resize array to actual found count
        assembly {
            mstore(result, found)
        }

        return result;
    }

    /**
     * @dev Get open proposals by author with pagination
     * @param _author The author's address
     * @param _offset Number of proposals to skip
     * @param _limit Maximum number of proposals to return
     */
    function getOpenProposalsByAuthor(address _author, uint256 _offset, uint256 _limit)
        external
        view
        returns (Proposal[] memory)
    {
        if (_limit == 0 || _limit > 50) _limit = 50;

        uint256[] memory authorProposalIds = proposalsByAuthor[_author];
        uint256 totalAuthorProposals = authorProposalIds.length;

        if (totalAuthorProposals == 0) {
            return new Proposal[](0);
        }

        uint256 found = 0;
        uint256 skipped = 0;
        Proposal[] memory result = new Proposal[](_limit);

        // Iterate through author's proposals from newest to oldest
        for (uint256 i = totalAuthorProposals; i > 0 && found < _limit; i--) {
            uint256 proposalId = authorProposalIds[i - 1];
            Proposal storage proposal = proposals[proposalId];

            // Check if proposal is open
            if (proposal.active && block.timestamp <= proposal.deadline) {
                if (skipped >= _offset) {
                    result[found] = proposal;
                    found++;
                } else {
                    skipped++;
                }
            }
        }

        // Resize array to actual found count
        assembly {
            mstore(result, found)
        }

        return result;
    }

    /**
     * @dev Get closed proposals by author with pagination
     * @param _author The author's address
     * @param _offset Number of proposals to skip
     * @param _limit Maximum number of proposals to return
     */
    function getClosedProposalsByAuthor(address _author, uint256 _offset, uint256 _limit)
        external
        view
        returns (Proposal[] memory)
    {
        if (_limit == 0 || _limit > 50) _limit = 50;

        uint256[] memory authorProposalIds = proposalsByAuthor[_author];
        uint256 totalAuthorProposals = authorProposalIds.length;

        if (totalAuthorProposals == 0) {
            return new Proposal[](0);
        }

        uint256 found = 0;
        uint256 skipped = 0;
        Proposal[] memory result = new Proposal[](_limit);

        // Iterate through author's proposals from newest to oldest
        for (uint256 i = totalAuthorProposals; i > 0 && found < _limit; i--) {
            uint256 proposalId = authorProposalIds[i - 1];
            Proposal storage proposal = proposals[proposalId];

            // Check if proposal is closed
            if (!proposal.active || block.timestamp > proposal.deadline) {
                if (skipped >= _offset) {
                    result[found] = proposal;
                    found++;
                } else {
                    skipped++;
                }
            }
        }

        // Resize array to actual found count
        assembly {
            mstore(result, found)
        }

        return result;
    }

    /**
     * @dev Get count of open proposals
     */
    function getOpenProposalCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            Proposal storage proposal = proposals[i];
            if (proposal.active && block.timestamp <= proposal.deadline) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Get count of closed proposals
     */
    function getClosedProposalCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            Proposal storage proposal = proposals[i];
            if (!proposal.active || block.timestamp > proposal.deadline) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Get count of open proposals by author
     * @param _author The author's address
     */
    function getOpenProposalCountByAuthor(address _author) external view returns (uint256) {
        uint256[] memory authorProposalIds = proposalsByAuthor[_author];
        uint256 count = 0;

        for (uint256 i = 0; i < authorProposalIds.length; i++) {
            uint256 proposalId = authorProposalIds[i];
            Proposal storage proposal = proposals[proposalId];
            if (proposal.active && block.timestamp <= proposal.deadline) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Get count of closed proposals by author
     * @param _author The author's address
     */
    function getClosedProposalCountByAuthor(address _author) external view returns (uint256) {
        uint256[] memory authorProposalIds = proposalsByAuthor[_author];
        uint256 count = 0;

        for (uint256 i = 0; i < authorProposalIds.length; i++) {
            uint256 proposalId = authorProposalIds[i];
            Proposal storage proposal = proposals[proposalId];
            if (!proposal.active || block.timestamp > proposal.deadline) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Check if an address has voted on a proposal
     * @param _proposalId The proposal ID
     * @param _voter The voter's address
     */
    function hasVoted(uint256 _proposalId, address _voter) external view returns (bool) {
        return votes[_proposalId][_voter].hasVoted;
    }

    /**
     * @dev Get the vote of an address on a proposal
     * @param _proposalId The proposal ID
     * @param _voter The voter's address
     */
    function getVote(uint256 _proposalId, address _voter) external view returns (bool) {
        if (!votes[_proposalId][_voter].hasVoted) revert("User has not voted");
        return votes[_proposalId][_voter].vote;
    }

    /**
     * @dev Check if a proposal is currently open for voting
     * @param _proposalId The proposal ID
     */
    function isProposalOpen(uint256 _proposalId) external view returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        return proposal.active && block.timestamp <= proposal.deadline;
    }

    /**
     * @dev Get the total number of proposals
     */
    function getTotalProposals() external view returns (uint256) {
        return proposalCount;
    }

    /**
     * @dev Get number of proposals by author
     * @param _author The author's address
     */
    function getAuthorProposalCount(address _author) external view returns (uint256) {
        return proposalsByAuthor[_author].length;
    }
}
