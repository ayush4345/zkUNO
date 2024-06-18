// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Playpoker is Ownable, Verifier {
    //using SafeMath for uint256;

    uint public smallBlind; 
    uint public bigBlind;

    uint256 constant NUM_CARDS = 52;
    uint256 constant NUM_PLAYERS = 10;
    uint256 constant NUM_BOARD_CARDS = 5;

    enum GamePhase { PreFlop, Flop, Turn, River, Showdown }
    GamePhase public currentPhase;

    struct Player {
        address addr;
        uint balance;
        bool isPlaying;
        bool hasFolded;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    struct Hand {
        bytes32[2][] holeCards;
        bytes32[5] communityCards;
        mapping(address => bytes32) playerCommitments;
        mapping(address => bool) revealed;
        mapping(address => bytes32[2]) revealedHands;
        mapping(address => bool) isValidProof;
        mapping(address => uint256) handStrength;
    }

    Hand private currentHand;
    bytes32[NUM_CARDS] public shuffledDeck;
    uint256 public currentBet;
    uint256 public pot;

    event GameStarted();
    event PlayerJoined(address indexed player);
    
    constructor(uint _smallBlind, uint _bigBlind, address initialOwner) Ownable(initialOwner) {
        smallBlind = _smallBlind;
        bigBlind = _bigBlind;
    }

    function joinGame() external payable {
        require(msg.value >= bigBlind, "Insufficient buy-in amount");
        players[msg.sender] = Player(msg.sender, msg.value, true, false);
        playerAddresses.push(msg.sender);
        emit PlayerJoined(msg.sender);
    }

    function startGame() external onlyOwner {
        require(playerAddresses.length >= 2, "Not enough players to start the game");
        currentPhase = GamePhase.PreFlop;
        emit GameStarted();
    }
    
}
