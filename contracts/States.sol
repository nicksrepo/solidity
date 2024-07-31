// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library StateCount {
 struct StateIndexer {
        uint256 value;
    }
     function currentStateIndexer(StateIndexer storage s_indexer) public view returns(uint256) {

        return s_indexer.value;

    }

    function incrementStateIndex(StateIndexer storage s_indexer) public  {
        s_indexer.value = s_indexer.value++;
    }

    function setIndexer(StateIndexer storage s_indexer) public {
        s_indexer.value = 0;
    }
}

abstract contract States {

    bool public paused;
    bool public vip_sale;
    bool public upkeep;
    bool public upgrading;
    bool public ready;
    bool public initializing;
    bool public initialized;

    error WrongState();

    enum AllStates {
        NONE,
        PAUSED,
        VIPSALE,
        UPKEEP,
        UPGRADING,
        READY,
        INITIALIZING
    }

  

    struct State {
        uint index;
        bytes32 _hash;
        string name;
        uint8 initializer;
        uint8 readyState;
    }

    struct RootState {
        State state;
        bytes32 _hash;
        uint256 timestamp;
    }

    mapping(bytes32 => AllStates) private _statesKeccaks;

   using StateCount for StateCount.StateIndexer;


    StateCount.StateIndexer internal s_indexer;

   

    // @dev map of the root state pseudo merkle tree 
    // @dev rootstateHash => RootState struct (need to match)
    // @dev => state index (needs to fit order triggered) => State
    // @dev RootState hash is the sha256 of self at start then all triggered states and times after
    mapping(bytes32 => mapping(uint => State)) private _stateTree;
    mapping(uint256 => bytes32) private _statesIndex;
    mapping(bytes32 => State) private _hashToState;
    mapping(bytes32 => mapping(bytes32 => bool)) private _stateDone;

    bytes32[] _sHashes;
    

    RootState private _rootState;

    bytes32 public statesRootHash;



    event StateChanged(address indexed _contract, AllStates _stateFrom, AllStates _stateTo, uint blockNumber, uint timestamp);

    State public currentState;
    State public previousState;

    function _setState(string memory _from, string memory _to) internal {
      
        s_indexer.incrementStateIndex();
       State memory _destState = State(s_indexer.currentStateIndexer(),
       bytes32(0), _to, 0, 0);

       (bytes32 sh, bytes32 rh)= _hashState(_destState);
       bytes32 _sh = sh;
       bytes32 _rh = rh;
       _destState._hash = _sh;
       bytes32 __rh = _rootState._hash;

       _hashToState[sh] = _destState;
       _statesIndex[s_indexer.currentStateIndexer()] = sh;
       bytes memory currentStateName = abi.encodePacked(currentState.name);

     if (keccak256(currentStateName) != keccak256(abi.encodePacked(_from))) {
        revert("invalid from state");
     }
       
       currentState = _destState;
       statesRootHash = _rh;
       _stateTree[__rh][s_indexer.currentStateIndexer()] = _destState;

    


    }

    function __States_init() public {
        require(initialized != true, "state already initialized");
        initializing = true;
        s_indexer.setIndexer(); // initialize indexer
        __RootState_init();
        initialized = true;
        initializing = false;
    }

    function __RootState_init() private {
        uint256 _currentTime = block.timestamp;
        uint256 __ct = _currentTime;
        uint256 _currentIndex = s_indexer.currentStateIndexer();
        State memory __rs = State(0, keccak256("STATE_NONE"), "NONE", 1, 0);
  
        bytes32 _rootHash = sha256(abi.encode(__rs, _currentTime));
        bytes32 __rh = _rootHash; // gas saving
        _rootState = RootState(__rs, __rh, __ct);
        _stateTree[__rh][_currentIndex] = __rs; // add root to tree map
        _statesIndex[_currentIndex] = __rh;
        _hashToState[__rh] = __rs;
        _sHashes[0] = __rh;
       
    }

    function _hashState(State memory state) private returns(bytes32 sh, bytes32 rh) {
        sh = keccak256(abi.encode(state));
        _sHashes.push(sh);
        __RootState_init();
        rh = _computeRootHash();
    }

    function _computeRootHash() private view returns(bytes32) {
        bytes32[] memory hs = _sHashes;
        
        bytes32[] memory work;
        for(uint i = 1; i < s_indexer.currentStateIndexer(); i++) {
            work[i] = keccak256(abi.encodePacked(hs[i], hs[i-1]));
            if(i + 1 == s_indexer.currentStateIndexer()) {
              return sha256(abi.encode(work[i]));
            }
        }
        revert("error processing state root");
    }

    


}