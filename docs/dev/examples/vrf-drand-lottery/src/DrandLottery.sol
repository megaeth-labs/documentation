// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IDrandOracleQuicknet} from "drand-verifier/interfaces/IDrandOracleQuicknet.sol";

/// @title DrandLottery
/// @notice A minimal commit-reveal lottery powered by drand quicknet randomness.
/// @dev Demonstrates how a consumer contract must add state and policy around the
///      stateless DrandOracleQuicknet verifier to make fair randomness usable.
///
///      Flow per game:
///      1. open()                -> creates a new game id, takes no funds.
///      2. enter(id) payable     -> anyone joins by depositing ETH into the pot.
///      3. close(id)             -> locks entries, commits to a *future* drand
///                                  round whose signature does not yet exist.
///      4. wait until publish_time(revealRound).
///      5. settle(id, sig)       -> anyone can submit the drand signature for
///                                  revealRound; contract verifies it, picks a
///                                  winner deterministically from the canonical
///                                  signature point, and pays out.
///
///      Security properties this consumer enforces (the verifier does NOT):
///      - Commit binding: revealRound is fixed at close-time, before the drand
///        network has signed that round.
///      - Input lock: no further `enter` calls allowed after close.
///      - Replay / freshness: `settled` flag prevents a second settlement;
///        `block.timestamp >= publish_time(revealRound)` prevents early reveal.
///      - Encoding footgun: randomness comes from `verifyNormalized`, which
///        hashes the *canonical* uncompressed signature point so compressed and
///        uncompressed drand beacons yield the same winner.
contract DrandLottery {
    IDrandOracleQuicknet public immutable oracle;

    /// @dev Margin between "now" and the reveal round. The drand network has not
    ///      yet produced a signature for `currentRound + MIN_FUTURE_ROUNDS`, so
    ///      no adversary can have seen the random value at close time. Two rounds
    ///      = ~6 seconds of safety on quicknet (3s period).
    uint64 public constant MIN_FUTURE_ROUNDS = 2;

    struct Game {
        uint64 revealRound; // 0 = open for entries
        bool settled;
        uint256 pot;
        address winner;
        address[] entrants;
    }

    uint256 public nextGameId;
    mapping(uint256 => Game) internal _games;

    event GameOpened(uint256 indexed id);
    event Entered(uint256 indexed id, address indexed player, uint256 amount);
    event GameClosed(uint256 indexed id, uint64 revealRound, uint64 publishTime);
    event GameSettled(uint256 indexed id, address indexed winner, uint256 pot, bytes32 randomness);

    error AlreadyClosed();
    error NotClosed();
    error AlreadySettled();
    error RoundNotPublished(uint64 publishTime, uint256 now_);
    error InvalidSignature();
    error NoEntrants();
    error NoValue();
    error PayoutFailed();

    constructor(IDrandOracleQuicknet oracle_) {
        oracle = oracle_;
    }

    /// @notice Opens a new empty game. Returns the game id.
    function open() external returns (uint256 id) {
        id = nextGameId++;
        emit GameOpened(id);
    }

    /// @notice Joins game `id` by depositing ETH into the pot.
    function enter(uint256 id) external payable {
        if (msg.value == 0) revert NoValue();
        Game storage g = _games[id];
        if (g.revealRound != 0) revert AlreadyClosed();
        g.entrants.push(msg.sender);
        g.pot += msg.value;
        emit Entered(id, msg.sender, msg.value);
    }

    /// @notice Locks entries and commits to a future drand round for the reveal.
    ///         After this, no one can `enter` and no one can change the outcome.
    function close(uint256 id) external {
        Game storage g = _games[id];
        if (g.revealRound != 0) revert AlreadyClosed();
        if (g.entrants.length == 0) revert NoEntrants();

        uint64 genesis = oracle.GENESIS_TIMESTAMP();
        uint64 period = oracle.PERIOD_SECONDS();
        // currentRound at this block. block.timestamp >= genesis is enforced by
        // the chain in practice (quicknet genesis is Aug 2023).
        uint64 currentRound = uint64((block.timestamp - genesis) / period) + 1;
        uint64 revealRound = currentRound + MIN_FUTURE_ROUNDS;

        g.revealRound = revealRound;
        uint64 publishTime = genesis + (revealRound - 1) * period;
        emit GameClosed(id, revealRound, publishTime);
    }

    /// @notice Submits the drand signature for the committed round. Verifies,
    ///         derives a canonical random value, picks a winner, pays out.
    /// @param id  The game id.
    /// @param sig The drand quicknet signature bytes for `revealRound`.
    ///            48-byte compressed or 96-byte uncompressed G1, either works.
    function settle(uint256 id, bytes calldata sig) external {
        Game storage g = _games[id];
        uint64 revealRound = g.revealRound;
        if (revealRound == 0) revert NotClosed();
        if (g.settled) revert AlreadySettled();

        uint64 publishTime = oracle.GENESIS_TIMESTAMP() + (revealRound - 1) * oracle.PERIOD_SECONDS();
        if (block.timestamp < publishTime) {
            revert RoundNotPublished(publishTime, block.timestamp);
        }

        // CEI: flip settled before the external verify + transfer. The oracle is
        // a trusted view call, but defence in depth costs nothing.
        g.settled = true;

        (bool ok,, bytes32 randomness) = oracle.verifyNormalized(revealRound, sig);
        if (!ok) {
            // Roll back the flag so a corrected submission can retry. The round
            // has already happened by now so a later submission cannot gain any
            // new information -- we're only protecting against a single bad
            // submission (e.g. wrong encoding) bricking the game.
            g.settled = false;
            revert InvalidSignature();
        }

        address winner = g.entrants[uint256(randomness) % g.entrants.length];
        g.winner = winner;
        uint256 pot = g.pot;
        emit GameSettled(id, winner, pot, randomness);

        (bool sent,) = winner.call{value: pot}("");
        if (!sent) revert PayoutFailed();
    }

    // ---------- views ----------

    function game(uint256 id)
        external
        view
        returns (uint64 revealRound, bool settled, uint256 pot, address winner, uint256 entrantCount)
    {
        Game storage g = _games[id];
        return (g.revealRound, g.settled, g.pot, g.winner, g.entrants.length);
    }

    function entrants(uint256 id) external view returns (address[] memory) {
        return _games[id].entrants;
    }

    function publishTimeOf(uint64 round) public view returns (uint64) {
        return oracle.GENESIS_TIMESTAMP() + (round - 1) * oracle.PERIOD_SECONDS();
    }
}
