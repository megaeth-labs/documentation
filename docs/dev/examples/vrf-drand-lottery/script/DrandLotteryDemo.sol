// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {IDrandOracleQuicknet} from "../src/interfaces/IDrandOracleQuicknet.sol";

/// @title DrandLotteryDemo
/// @notice End-to-end demo of commit-reveal randomness using DrandOracleQuicknet.
/// @dev Single-slot lottery: open() commits entrants + a future quicknet round,
/// settle() verifies the drand signature for that round and picks a winner.
/// Reset by calling open() again after settlement.
contract DrandLotteryDemo {
    IDrandOracleQuicknet public immutable oracle;
    uint64 public immutable GENESIS;
    uint64 public immutable PERIOD;

    address[] public entrants;
    uint64 public revealRound;
    bool public settled;
    address public winner;
    bytes32 public randomness;

    event LotteryOpened(uint64 revealRound, uint256 entrantCount, uint256 publishTime);
    event LotterySettled(uint64 revealRound, address winner, uint256 winnerIndex, bytes32 randomness);

    constructor(IDrandOracleQuicknet _oracle) {
        oracle = _oracle;
        GENESIS = _oracle.GENESIS_TIMESTAMP();
        PERIOD = _oracle.PERIOD_SECONDS();
    }

    /// @notice Commit a participant set and a round in the future.
    /// @param _entrants Participant addresses (duplicates allowed).
    /// @param minDelaySeconds Seconds from now; committed round must have `publish_time > now`.
    function open(address[] calldata _entrants, uint64 minDelaySeconds) external {
        require(_entrants.length > 0, "no entrants");
        require(revealRound == 0 || settled, "lottery in flight");

        delete entrants;
        settled = false;
        winner = address(0);
        randomness = bytes32(0);
        for (uint256 i; i < _entrants.length; i++) entrants.push(_entrants[i]);

        uint64 round = uint64((block.timestamp + minDelaySeconds - GENESIS) / PERIOD + 1);
        revealRound = round;

        uint256 publishTime = GENESIS + uint256(round - 1) * PERIOD;
        require(publishTime > block.timestamp, "round already published");

        emit LotteryOpened(round, _entrants.length, publishTime);
    }

    /// @notice Reveal: drand signature for the committed round.
    function settle(bytes calldata sig) external {
        require(revealRound != 0 && !settled, "not settlable");
        uint256 publishTime = GENESIS + uint256(revealRound - 1) * PERIOD;
        require(block.timestamp >= publishTime, "round not yet published");

        (bool ok, bytes32 r,) = oracle.verifyNormalized(revealRound, sig);
        require(ok, "bad signature");

        uint256 idx = uint256(r) % entrants.length;
        settled = true;
        randomness = r;
        winner = entrants[idx];
        emit LotterySettled(revealRound, winner, idx, r);
    }

    function entrantCount() external view returns (uint256) {
        return entrants.length;
    }

    function publishTime() external view returns (uint256) {
        return GENESIS + uint256(revealRound - 1) * PERIOD;
    }
}
