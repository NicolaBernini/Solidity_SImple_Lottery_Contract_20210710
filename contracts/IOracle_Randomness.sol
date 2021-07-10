pragma solidity ^0.8.0;

interface IOracle_Randomness {
    
    function get_random_number(uint256 N) external view returns(uint256); 

}



