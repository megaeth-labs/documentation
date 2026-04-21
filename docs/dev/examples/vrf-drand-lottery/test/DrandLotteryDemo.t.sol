// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {DrandLotteryDemo, IDrandOracleQuicknet} from "../src/DrandLotteryDemo.sol";

/// @dev Returns a caller-chosen verification result.
/// Decouples lottery logic from the real BLS verifier so unit tests stay fast.
contract MockOracleQuicknet is IDrandOracleQuicknet {
    uint64 public constant PERIOD_SECONDS = 3;
    uint64 public constant GENESIS_TIMESTAMP = 1692803367;

    bool internal _ok = true;
    bytes32 internal _r;

    function setNext(bool ok, bytes32 r) external {
        _ok = ok;
        _r = r;
    }

    function verifyNormalized(uint64, bytes calldata)
        external
        view
        returns (bool, bytes32, bytes32)
    {
        return (_ok, _r, _r);
    }
}

contract DrandLotteryDemoTest is Test {
    DrandLotteryDemo internal lottery;
    MockOracleQuicknet internal oracle;

    address internal constant A = address(0xA);
    address internal constant B = address(0xB);
    address internal constant C = address(0xC);
    address internal constant D = address(0xD);

    function setUp() public {
        oracle = new MockOracleQuicknet();
        lottery = new DrandLotteryDemo(IDrandOracleQuicknet(address(oracle)));

        // Warp to a realistic drand-era time so round math fits in uint64 without underflow.
        vm.warp(1_700_000_000);
    }

    function _entrants() internal pure returns (address[] memory a) {
        a = new address[](4);
        a[0] = A;
        a[1] = B;
        a[2] = C;
        a[3] = D;
    }

    function testOpenCommitsFutureRound() public {
        lottery.open(_entrants(), 30);
        uint64 round = lottery.revealRound();
        assertGt(round, 0);
        assertEq(lottery.entrantCount(), 4);
        assertFalse(lottery.settled());
        assertGt(lottery.publishTime(), block.timestamp);
    }

    function testOpenRevertsOnEmpty() public {
        address[] memory empty;
        vm.expectRevert("no entrants");
        lottery.open(empty, 30);
    }

    function testSettleRevertsBeforePublish() public {
        lottery.open(_entrants(), 30);
        vm.expectRevert("round not yet published");
        lottery.settle(hex"");
    }

    function testSettleRevertsOnBadSignature() public {
        lottery.open(_entrants(), 30);
        vm.warp(lottery.publishTime());
        oracle.setNext(false, bytes32(0));
        vm.expectRevert("bad signature");
        lottery.settle(hex"");
    }

    function testSettlePicksWinnerDeterministically() public {
        lottery.open(_entrants(), 30);
        vm.warp(lottery.publishTime());

        // index 2 → C
        bytes32 r = bytes32(uint256(6));
        oracle.setNext(true, r);

        lottery.settle(hex"");

        assertTrue(lottery.settled());
        assertEq(lottery.randomness(), r);
        assertEq(lottery.winner(), C);
    }

    function testSettleRevertsOnSecondCall() public {
        lottery.open(_entrants(), 30);
        vm.warp(lottery.publishTime());
        oracle.setNext(true, bytes32(uint256(1)));
        lottery.settle(hex"");
        vm.expectRevert("not settlable");
        lottery.settle(hex"");
    }

    function testOpenResetsAfterSettle() public {
        lottery.open(_entrants(), 30);
        vm.warp(lottery.publishTime());
        oracle.setNext(true, bytes32(uint256(0)));
        lottery.settle(hex"");
        assertTrue(lottery.settled());

        // New round — should succeed because previous one settled.
        lottery.open(_entrants(), 30);
        assertFalse(lottery.settled());
        assertEq(lottery.winner(), address(0));
    }

    function testOpenRevertsWhileInFlight() public {
        lottery.open(_entrants(), 30);
        vm.expectRevert("lottery in flight");
        lottery.open(_entrants(), 30);
    }
}
