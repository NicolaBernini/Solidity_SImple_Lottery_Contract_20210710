pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOracle_Randomness.sol"; 

contract Lottery {
    uint8 public N;
    uint256 public min_stake;
    uint256 public current_num_players;
    uint256 public earnable; 
    mapping (uint8 => address) players;
    
    // If not address(0) --> the ERC20 Token used to play the game
    // If address(0) --> play with ETH
    address public token;
    
    address public oracle_randomness; 
    
    mapping (address => uint8) internal player_id;
    mapping (address => uint256) internal extra_staking;
    
    address public owner;
    
    bool public is_blocked; 
    
    event Winner(address winner, uint256 amount); 
    event PlayerIn(address player, uint256 amount);
    event Pay(address target, uint256 amount);
    event PlayerRemoved(address player);
    
    constructor (uint8 _N, uint256 _min_stake, address _token, address _oracle_randomness) {
        N = _N;
        min_stake = _min_stake;
        token = _token; 
        oracle_randomness = _oracle_randomness;
        owner = msg.sender;
    }
    
    modifier only_onwer {
        require(msg.sender == owner, "Owner!"); 
        _;
    }
    
    modifier active {
        require(is_blocked == false, "Maintenance");
        _;
    }
    
    modifier only_player {
        require( player_id[msg.sender] > 0, "Not a player" );
        _;
    }
    
    function set_N(uint8 _N) external only_onwer {
        N = _N;
    }
    
    function set_min_stake(uint256 _min_stake) external only_onwer {
        min_stake = _min_stake;
    }
    
    function set_token(address _token) external only_onwer {
        token = _token;
    }
    
    function set_is_blocked(bool _is_blocked) external only_onwer {
        is_blocked = _is_blocked;
    }
    
    function reset() external only_onwer {
        // Setting is_blocked locks the SC during this operation to avoid refunding a player causes it to call some other function in response   
        is_blocked = true;
        for(uint8 i=0; i<N; ++i){
            if( players[i] != address(0) ) {
                refund(players[i]); 
            }
        }
        is_blocked = false;
    }
    
    function reset_game() internal {
        for(uint8 i=0; i<N; ++i) {
            remove_player( players[i] );
        }
    }
    
    function get_my_stake() view external only_player returns(uint256) {
        return min_stake + extra_staking[msg.sender]; 
    }
    
    function get_stake_by_id(uint8 id) view external only_onwer returns (uint256) {
        require( players[id] != address(0), "Invalid Player ID" ); 
        return min_stake + extra_staking[ players[id] ]; 
    }
    
    function get_stake_by_addr(address player) view external only_onwer returns (uint256) {
        require (player_id[player] > 0, "Invalid Player Addr");
        return min_stake + extra_staking[ player ]; 
    }
    
    
    function pay(address target, uint256 amount) internal {
        if (token != address(0)) {
            // Assuming ERC20
            require(IERC20(token).transfer(target, amount));
        } 
        else {
            // Asuming ETH
            address payable wallet = payable(target);
            wallet.transfer(amount);
        }
        emit Pay(target, amount);
    }
    
    function earn() external only_onwer {
        require(earnable > 0, "Earnable"); 
        pay(owner, earnable);
        earnable = 0; 
    }
    
    function remove_player(address player) internal {
        require( player_id[player] > 0, "Invalid Player" ); 
        players[ player_id[player]-1 ] = address(0);
        player_id[player] = 0;
        extra_staking[player] = 0;
        current_num_players -= 1;
        
        emit PlayerRemoved(player); 
    }
    
    function stake(uint256 amount) external payable active {
        require(msg.sender != owner, "Owner");
        require(player_id[msg.sender] == 0, "Stake!"); 
        if (token == address(0)) {
            // Assuming ETH
            amount = msg.value;
        }
        require(amount >= min_stake, "Min Stake");
        
        if(token != address(0)) {
            // Assuming ERC20
            require(IERC20(token).transferFrom(msg.sender, address(this), amount));            
        }
        
        for (uint8 i=0; i<N; i++) {
            if (players[i] == address(0)) {
                players[i] = msg.sender; 
                player_id[msg.sender] = i+1;
                break;
            }
        }
        
        require(player_id[msg.sender] > 0, "Sanity Check");

        current_num_players += 1;
        
        if(amount > min_stake) {
            extra_staking[msg.sender] = amount - min_stake; 
        }
        
        emit PlayerIn(msg.sender, amount);
    }
    
    
    function ask_refund() external active only_player {
        // Can not refund if everbody else is ready to play 
        require(current_num_players < N, "Complete");
        
        // Before refunding need to have staken something 
        require(player_id[msg.sender] > 0, "Stake!");

        pay(msg.sender, min_stake + extra_staking[msg.sender]);

        remove_player(msg.sender); 
    }
    
    
    
    function refund(address player) public only_onwer {
        pay(msg.sender, min_stake + extra_staking[msg.sender]);
        remove_player(player);
    }
    
    
    /**
      * Lottery Ticket 
      */
    function play() external active only_player {
        require(current_num_players == N, "Not complete");
        //uint8 winner = uint8(block.timestamp) % N;
        uint8 winner = uint8(IOracle_Randomness(oracle_randomness).get_random_number(N)); 
        uint256 prize = (N * min_stake * 99) / 100;
        earnable += (N * min_stake) - prize; 
        
        pay(players[winner], prize); 
        
        emit Winner(players[winner], prize); 
        
        reset_game();
    }
    
}

