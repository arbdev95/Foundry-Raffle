// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "lib/forge-std/src/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

contract raffleTest is CodeConstants, Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        //ARRANGE
        vm.prank(PLAYER);
        //ACT/ASSERT
        vm.expectRevert(Raffle.Raffle__sendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordPlayersWhenTheyEnter() public {
        //ARRANGE
        vm.prank(PLAYER);
        //ACT
        raffle.enterRaffle{value: entranceFee}();
        //aSSERT
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        //ARRANGE
        vm.prank(PLAYER);
        //ACT
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        //ASSERT
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersEnterWhileRaffleIsCalculating()
        public
        raffleEntered
    {
        //ARRANGE
        raffle.performUpKeep(""); //<== THIS WIL CHANGE THE STATE OF CALCULATION
        //ACT / ASSERT
        vm.expectRevert(Raffle.Raffle__RaffleIsNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*///////////////////////////////////////////////////////////////////////////
                                    CHECK UPKEEP
    ///////////////////////////////////////////////////////////////////////////*/
    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        //ARRANGE
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //ACT
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");

        //ASSERT
        assert(!upKeepNeeded);
    }

    function testCheckUpReturnsFalseIfRaffleIsntOpen() public raffleEntered {
        //ARRANGE
        raffle.performUpKeep("");
        //ACT
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        //ASSERT
        assert(!upKeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // ARRANGE
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        // ACT
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        //ASSERT
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsTrueWhenParametersAreGood()
        public
        raffleEntered
    {
        //ARRANGE
        //the modifier
        //ACT
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");

        //ASSERT
        assert(upKeepNeeded);
    }

    /*///////////////////////////////////////////////////////////////////////////
                                    PERFORM UPKEEP
    ///////////////////////////////////////////////////////////////////////////*/

    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue()
        public
        raffleEntered
    {
        //ARRANGE
        //the modifier
        //ACT / ASSERT
        raffle.performUpKeep("");
    }

    function testPerformUpKeepRevertsIfCheckUpKeepIsFalse() public {
        //ARRANGE
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        //ACT / ASSERT
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.performUpKeep("");
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsEvent()
        public
        raffleEntered
    {
        // ARRANGE
        //the modifier
        //ACT
        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        //ASSERT
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    /*///////////////////////////////////////////////////////////////////////////
                                    FULFILLRANDOMWORDS
    ///////////////////////////////////////////////////////////////////////////*/
    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function testFulfillrandomWordsCanOnlyBeCalledAfterPerformUpKeep(
        uint256 randomRequestId
    ) public raffleEntered skipFork {
        //ARRANGE / ACT / ASSERT
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillrandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        raffleEntered
        skipFork
    {
        //ARRANGE
        uint256 additionalEntrants = 3; //4 PEOPLE TOTAL
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address newPlayer = address(uint160(i)); // ADDRESS(1) or ADDRESS(2) OR ECC....
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        //ACT
        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );
        //ASSERT

        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
