// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Voting.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy the BallotBox contract
        BallotBox ballotBox = new BallotBox();

        console.log("=== BallotBox Deployment ===");
        console.log("BallotBox deployed to:", address(ballotBox));
        console.log("Deployer address:", msg.sender);
        console.log("Chain ID:", block.chainid);

        // Log some initial state
        console.log("Initial proposal count:", ballotBox.proposalCount());
        console.log("Max title length:", ballotBox.MAX_TITLE_LENGTH());
        console.log("Max description length:", ballotBox.MAX_DESCRIPTION_LENGTH());

        vm.stopBroadcast();

        console.log("=== Deployment Complete ===");
        console.log("");
        console.log("Available Contract Functions:");
        console.log("Core Functions:");
        console.log("- createProposal(title, description, ipfsHash, deadline)");
        console.log("- vote(proposalId, voteChoice)");
        console.log("- getProposal(proposalId)");
        console.log("");
        console.log("Filtering Functions (NEW):");
        console.log("- getOpenProposals(offset, limit)");
        console.log("- getClosedProposals(offset, limit)");
        console.log("- getOpenProposalsByAuthor(author, offset, limit)");
        console.log("- getClosedProposalsByAuthor(author, offset, limit)");
        console.log("");
        console.log("Count Functions (NEW):");
        console.log("- getOpenProposalCount()");
        console.log("- getClosedProposalCount()");
        console.log("- getOpenProposalCountByAuthor(author)");
        console.log("- getClosedProposalCountByAuthor(author)");
        console.log("");
        console.log("Legacy Functions:");
        console.log("- getProposals(offset, limit) - All proposals");
        console.log("- getProposalsByAuthor(author, offset, limit)");
        console.log("");
        console.log("Next steps:");
        console.log("1. Verify contract on Etherscan (if on testnet/mainnet)");
        console.log("2. Test contract functionality with new filtering");
        console.log("3. Update frontend to use efficient filtering functions");
    }
}
