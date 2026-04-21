// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Test, console2} from "forge-std/Test.sol";
import {DrandOracleQuicknet} from "drand-verifier/oracles/DrandOracleQuicknet.sol";
import {IDrandOracleQuicknet} from "drand-verifier/interfaces/IDrandOracleQuicknet.sol";
import {DrandLottery} from "../src/DrandLottery.sol";

contract DrandLotteryTest is Test {
    // Canonical quicknet vector from DrandVerifier's own test suite.
    uint64 internal constant ROUND = 20791007;
    bytes internal constant SIG_COMPRESSED =
        hex"8d2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac5";

    // Quicknet constants mirrored so we can fast-forward chain time.
    uint64 internal constant GENESIS_TS = 1692803367;
    uint64 internal constant PERIOD = 3;

    DrandOracleQuicknet internal oracle;
    DrandLottery internal lottery;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public {
        oracle = new DrandOracleQuicknet();
        lottery = new DrandLottery(IDrandOracleQuicknet(address(oracle)));

        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(carol, 10 ether);
    }

    function testFullCommitRevealFlow() public {
        // 1. Open game.
        uint256 id = lottery.open();

        // 2. Three players enter. We set block.timestamp to a point BEFORE
        //    the canonical round is published so MIN_FUTURE_ROUNDS lands exactly on ROUND.
        //    publish_time(ROUND) = genesis + (ROUND - 1) * 3
        //    currentRound we want = ROUND - MIN_FUTURE_ROUNDS = ROUND - 2
        //    → block.timestamp s.t. (ts - genesis) / 3 + 1 = ROUND - 2
        //                           ts = genesis + (ROUND - 3) * 3
        uint256 closeTs = GENESIS_TS + uint256(ROUND - 3) * PERIOD;
        vm.warp(closeTs);

        vm.prank(alice);
        lottery.enter{value: 1 ether}(id);
        vm.prank(bob);
        lottery.enter{value: 2 ether}(id);
        vm.prank(carol);
        lottery.enter{value: 3 ether}(id);

        // 3. Close → committedRound should equal ROUND.
        lottery.close(id);
        (uint64 revealRound,,,, uint256 count) = lottery.game(id);
        assertEq(revealRound, ROUND, "revealRound mismatch");
        assertEq(count, 3, "entrants");

        // 4. Fast-forward to publish time.
        vm.warp(lottery.publishTimeOf(ROUND));

        // 5. Settle with the known-good signature.
        uint256 aliceBalBefore = alice.balance;
        uint256 bobBalBefore = bob.balance;
        uint256 carolBalBefore = carol.balance;

        lottery.settle(id, SIG_COMPRESSED);

        (,, uint256 pot, address winner,) = lottery.game(id);
        assertEq(pot, 6 ether, "pot");
        assertTrue(winner == alice || winner == bob || winner == carol, "winner must be one of entrants");

        // One of the three got the 6 ether pot.
        uint256 totalDelta =
            (alice.balance - aliceBalBefore) + (bob.balance - bobBalBefore) + (carol.balance - carolBalBefore);
        assertEq(totalDelta, 6 ether, "payout total");
    }

    function testCannotEnterAfterClose() public {
        uint256 id = lottery.open();
        vm.warp(GENESIS_TS + uint256(ROUND - 3) * PERIOD);

        vm.prank(alice);
        lottery.enter{value: 1 ether}(id);
        lottery.close(id);

        vm.prank(bob);
        vm.expectRevert(DrandLottery.AlreadyClosed.selector);
        lottery.enter{value: 1 ether}(id);
    }

    function testCannotSettleBeforeRoundPublished() public {
        uint256 id = lottery.open();
        vm.warp(GENESIS_TS + uint256(ROUND - 3) * PERIOD);
        vm.prank(alice);
        lottery.enter{value: 1 ether}(id);
        lottery.close(id);

        // time hasn't advanced; reveal round publish time is in the future.
        vm.expectRevert();
        lottery.settle(id, SIG_COMPRESSED);
    }

    function testSettleRejectsWrongSignature() public {
        uint256 id = lottery.open();
        vm.warp(GENESIS_TS + uint256(ROUND - 3) * PERIOD);
        vm.prank(alice);
        lottery.enter{value: 1 ether}(id);
        lottery.close(id);
        vm.warp(lottery.publishTimeOf(ROUND));

        // Bit-flip the signature; must revert InvalidSignature and leave game unsettled.
        bytes memory tampered = bytes.concat(SIG_COMPRESSED);
        tampered[0] = bytes1(uint8(tampered[0]) ^ 0x01);

        vm.expectRevert(DrandLottery.InvalidSignature.selector);
        lottery.settle(id, tampered);

        (, bool settled,,,) = lottery.game(id);
        assertFalse(settled, "must stay unsettled so a correct submission can retry");

        // And retry with the real signature succeeds.
        lottery.settle(id, SIG_COMPRESSED);
        (, settled,,,) = lottery.game(id);
        assertTrue(settled);
    }

    function testCannotSettleTwice() public {
        uint256 id = lottery.open();
        vm.warp(GENESIS_TS + uint256(ROUND - 3) * PERIOD);
        vm.prank(alice);
        lottery.enter{value: 1 ether}(id);
        lottery.close(id);
        vm.warp(lottery.publishTimeOf(ROUND));

        lottery.settle(id, SIG_COMPRESSED);
        vm.expectRevert(DrandLottery.AlreadySettled.selector);
        lottery.settle(id, SIG_COMPRESSED);
    }
}
