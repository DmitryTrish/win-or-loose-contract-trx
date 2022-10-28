// SPDX-License-Identifier: 0BSD
pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Strings.sol";

contract WinOrLoose {
    address public owner;
    mapping(address => uint) private balances;
    address[] private balanceBuffer;
    uint private jackpot;
    uint private fee = 2; // owner`s fee in percent

    constructor () {
        owner = msg.sender;
    }
    
    /**
     * Players getter.
     * Returns [address => balance][]
     */
    function getPlayers() public view returns (string[2][] memory) {
        string[2][] memory output = new string[2][](balanceBuffer.length);
    
        for (uint i = 0; i < balanceBuffer.length; i++) {
            output[i] = [
                Strings.toHexString(balanceBuffer[i]),
                Strings.toString(balances[balanceBuffer[i]])
            ];
        }
        
        return output;
    }
    
    /**
     * Jackpot getter.
     * Returns number
     */
    function getJackpot() public view returns (uint) {
        return jackpot;
    }
    
    // GAME LOGIC
    
    /**
     * Sign up the game.
     * Require to transfer balance.
     */
    function playGame() public payable {
        require(msg.value >= 10_000_000, "Minimum playable value: 10 TRX");
        require(balances[msg.sender] == 0, "You are already in game");
        
        balances[msg.sender] = msg.value;
        balanceBuffer.push(msg.sender);
        jackpot += msg.value;
    }
    
    /**
     * Increment in-game balance.
     * Require to transfer balance and be in game.
     */
    function addBalance() public payable {
        require(msg.value >= 10_000_000, "Minimum playable value: 10 TRX");
        require(balances[msg.sender] != 0, "You are not in game");
        
        balances[msg.sender] += msg.value;
        jackpot += msg.value;
    }
    
    /**
     * Release game.
     * Transfer jackpot to winner.
     * Require admin rights and winner address.
     */
    function releaseGame(address winner) public {
        require(msg.sender == owner, "Access Denied");

        uint winFee = jackpot / 100 * fee;
        uint winAmount = jackpot - winFee;

        payable(winner).transfer(winAmount);  // send trx to winner
        payable(owner).transfer(winFee);    // send fee to owner
        jackpot = 0;

        // clear players
        for (uint i = 0; i < balanceBuffer.length; i++) {
            delete balances[balanceBuffer[i]];
        }
        
        balanceBuffer = new address[](0);
    }
}
