pragma solidity ^0.8.0;

contract Oracle_Randomness {
    
    function get_random_number(uint256 N) external view returns(uint256) {
        return block.timestamp % N; 
    }

}

