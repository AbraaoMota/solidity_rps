pragma solidity ^0.4.0;
contract RockPaperScissors {
    
    mapping (address => uint) payouts;
    mapping (string => mapping(string => uint)) winnerMatrix;
    bool gameOver;
    address p1;
    address p2;
    string p1Move;
    string p2Move;
    bytes32 p1Commitment;
    bytes32 p2Commitment;
    uint firstReveal;
    uint gameLengthThreshold;
    
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
        gameLengthThreshold = 300;
    }
    
    function registerToPlay() public payable
        hasPayedGameFee(3)
        isNewPlayer
    {
        if (p1 == 0) {
            p1 = msg.sender;
        } else if (p2 == 0) {
            p2 = msg.sender;
        }
    }
    
    modifier hasPayedGameFee(uint gameFee) {
        require (msg.value >= gameFee);
        _;
    }
    
    modifier isNewPlayer() {
        p1 == 0 || p2 == 0;
        _;
    }
    
    modifier isValidPlayer() {
        require (msg.sender == p1 || msg.sender == p2);
        _;
    }
    
    modifier ongoingGame() {
        require(!gameOver);
        _;
    }
    
    function isValidMove(string move) pure internal returns (bool valid){
        return (keccak256(move) == keccak256("rock")  ||
                keccak256(move) == keccak256("paper") ||
                keccak256(move) == keccak256("scissors"));
    }
    
    function commitMove(string move, string randomString) public payable
        isValidPlayer
        ongoingGame
    {
        require(isValidMove(move));
        if (msg.sender == p1) {
            // At this point, we only store a hashed commitment to a move,
            // not the move itself.
            p1Commitment = keccak256(keccak256(move) ^ keccak256(randomString));
        } else if (msg.sender == p2) {
            p2Commitment = keccak256(keccak256(move) ^ keccak256(randomString));
        }
    }
    
    function revealMove(string move, string randomString) public payable
        isValidPlayer
        ongoingGame
    {
        require(isValidMove(move));
        // We now store the real player move, which *MUST* validate against the
        // initial commitment for the game to proceed
        if (msg.sender == p1 && keccak256(keccak256(move) ^ keccak256(randomString)) == p1Commitment) {
            p1Move = move;
            if (p2Commitment == 0) {
                // Player 1 was the first to reveal, start the timer for p2 to reveal
                firstReveal = now;
            }
        } else if (msg.sender == p2 && keccak256(keccak256(move) ^ keccak256(randomString)) == p2Commitment) {
            p2Move = move;
            if (p1Commitment == 0) {
                // Player 2 was the first to reveal, start the timer for p1 to reveal
                firstReveal = now;
            }
        }
    }
    
    function decideWinner() public {
        if (keccak256(p1Move) != keccak256("") && keccak256(p2Move) != keccak256("")) {
            // Handle the case where both players have revealed within the time period
            gameOver = true;
            uint winner = winnerMatrix[p1Move][p2Move];
            payWinner(winner);
            resetGame();
        } else if (now > firstReveal + gameLengthThreshold) {
            gameOver = true;
            // One of the players has taken too long to reveal, award funds to 
            // first player to reveal
            if (keccak256(p1Move) != keccak256("")) {
                // P1 revealed first, gets winnings
                p1.transfer(this.balance);
                resetGame();
            } else if (keccak256(p2Move) != keccak256("")) {
                // P2 revealed first, gets winnings
                p2.transfer(this.balance);
                resetGame();
            }
        }
    }
    
    function resetGame() private {
        delete p1;
        delete p2;
        gameOver = false;
        delete p1Move;
        delete p2Move;
        delete p1Commitment;
        delete p2Commitment;
        delete firstReveal;
    }
    
    function payWinner(uint winner) private {
        if (winner == 0) {
            p1.transfer(this.balance / 2);
            p2.transfer(this.balance);
        } else if (winner == 1) {
            p1.transfer(this.balance);
        } else {
            p2.transfer(this.balance);
        }
    }
}
