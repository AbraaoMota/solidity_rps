pragma solidity ^0.4.0;
contract RockPaperScissors {
    
    mapping (address => uint) payouts;
    mapping (string => mapping(string => uint)) winnerMatrix;
    bool gameOver;
    address player1;
    address player2;
    bool player1HasPlayed;
    string p1Move;
    
    function RockPaperScissors() public payable {
        winnerMatrix["paper"]["paper"] = 0;
        winnerMatrix["paper"]["rock"] = 1;
        winnerMatrix["paper"]["scissors"] = 2;
        winnerMatrix["rock"]["paper"] = 2;
        winnerMatrix["rock"]["rock"] = 0;
        winnerMatrix["rock"]["scissors"] = 1;
        winnerMatrix["scissors"]["paper"] = 1;
        winnerMatrix["scissors"]["rock"] = 2;
        winnerMatrix["scissors"]["scissors"] = 0;
        gameOver = false;
        player1HasPlayed = false;
        p1Move = "";
    }
    
    function registerToPlay() public payable
        hasPayedGameFee(3)
        isNewPlayer
    {
        if (player1 == 0) {
            player1 = msg.sender;
        } else if (player2 == 0) {
            player2 = msg.sender;
        }
    }
    
    modifier hasPayedGameFee(uint gameFee) {
        require (msg.value >= gameFee);
        _;
    }
    
    modifier isNewPlayer() {
        player1 == 0 || player2 == 0;
        _;
    }
    
    modifier isValidPlayer() {
        require (msg.sender == player1 || msg.sender == player2);
        _;
    }
    
    modifier ongoingGame() {
        require(!gameOver);
        _;
    }
    
    function play(string move) public payable
        isValidPlayer
        ongoingGame
    {
        require(isValidMove(move));
        if (msg.sender == player1 && !player1HasPlayed) {
            p1Move = move;
            player1HasPlayed = true;
        } else if (msg.sender == player2 && player1HasPlayed ) {
            uint winner = winnerMatrix[p1Move][move];
            gameOver = true;
            require(winner == 1 || winner == 2 || winner == 0);
            payWinner(winner);
            resetGame();
        } else {
            // Game shouldn't get here?
            assert(false);
        }
        
    }
    
    function resetGame() private {
        player1 = 0;
        player2 = 0;
        player1HasPlayed = false;
        gameOver = false;
        p1Move = "";
        
    }
    
    function payWinner(uint winner) private {
        if (winner == 0) {
            player1.transfer(this.balance / 2);
            player2.transfer(this.balance);
        } else if (winner == 1) {
            player1.transfer(this.balance);
        } else {
            player2.transfer(this.balance);
        }
        
    }
    
    function isValidMove(string move) pure internal returns (bool valid){
        return (keccak256(move) == keccak256("rock")  ||
                keccak256(move) == keccak256("paper") ||
                keccak256(move) == keccak256("scissors"));
    }
}
