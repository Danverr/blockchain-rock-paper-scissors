// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract RPSGame {
    enum Stage {
        WaitingPlayers,
        FirstPlayerJoined,
        SecondPlayerJoined,
        FirstPlayerCommited,
        SecondPlayerCommited,
        FirstPlayerRevealed,
        SecondPlayerRevealed
    }

    event StageChanged(Stage newStage);

    enum Choice {
        Default,
        Rock,
        Paper,
        Scissors
    }

    event WinnerChanged(address winner);

    struct PlayerChoice {
        address playerAddress;
        bytes32 commitHash;
        Choice choice;
    }

    struct CurrentGame {
        PlayerChoice player1;
        PlayerChoice player2;
    }

    CurrentGame public currentGame;

    Stage public stage;

    function setStage(Stage newStage) private {
        stage = newStage;
        emit StageChanged(newStage);
    }

    function joinPlayer() public {
        if(stage == Stage.WaitingPlayers) {
            currentGame.player1.playerAddress = msg.sender;
            setStage(Stage.FirstPlayerJoined);
        }
        else if(stage == Stage.FirstPlayerJoined) {
            currentGame.player2.playerAddress = msg.sender;
            setStage(Stage.SecondPlayerJoined);
        }
        else {
            revert("Game is already started");
        }
    }

    function commitMove(
        bytes32 hash
    ) external {
        if(currentGame.player1.playerAddress == msg.sender) {
            currentGame.player1.commitHash = hash;
            setStage(Stage.FirstPlayerCommited);
        }
        else if(currentGame.player2.playerAddress == msg.sender) {
            currentGame.player2.commitHash = hash;
            setStage(Stage.SecondPlayerCommited);
        }
        else {
            revert("The address is not playing this game");
        }
    }
    
    bytes32 public hash;

    function revealMove(
        uint256 moveId,
        string memory salt
    ) external {
        hash = keccak256(abi.encodePacked(moveId, salt));
        if(currentGame.player1.playerAddress == msg.sender) {
            require(currentGame.player1.commitHash == hash, "hash is broken");
            currentGame.player1.choice = Choice(moveId);
            setStage(Stage.FirstPlayerRevealed);
        }
        else if(currentGame.player2.playerAddress == msg.sender) {
            require(currentGame.player2.commitHash == hash, "hash is broken");
            currentGame.player2.choice = Choice(moveId);
            setStage(Stage.SecondPlayerRevealed);
        }
        else {
            revert("The address is not playing this game");
        }
    }

    function getWinner() external {
        require(currentGame.player1.choice == Choice.Default || currentGame.player2.choice == Choice.Default, "game is not over yet");
        if(currentGame.player1.choice == currentGame.player2.choice) {
            emit WinnerChanged(address(0));
        }
        else if(
            (currentGame.player1.choice == Choice.Rock && currentGame.player1.choice == Choice.Scissors) 
            ||
            (currentGame.player1.choice == Choice.Paper && currentGame.player1.choice == Choice.Rock) 
            ||
            (currentGame.player1.choice == Choice.Scissors && currentGame.player1.choice == Choice.Paper) 
        ) {
            emit WinnerChanged(currentGame.player1.playerAddress);
        } 
        else {
            emit WinnerChanged(currentGame.player2.playerAddress);
        }
        clear();
    }

    function clear() private {
        setStage(Stage.WaitingPlayers);
        currentGame.player1.choice = Choice.Default;
        currentGame.player2.choice = Choice.Default;
    }
}