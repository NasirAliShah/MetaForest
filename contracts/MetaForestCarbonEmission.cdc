pub contract MetaForestCarbonEmission {

    /*metaForestAccess private _access;
    mapping(address => uint256) private _totalEmission;
    mapping(address => uint256) private _lastEmission;
    mapping(address => uint256) private _lastUpdate;
    uint256 private _blockNumOfOneDay;
    */
    access(self) var totalEmission : {Address: UInt8}
    access(self) var lastEmission : {Address: UInt8}
    access(self) var lastUpdate : {Address:UInt8}
    pub var blockNumOfOneDay: [UInt8;32]

    /*
      function lastBalanceOf(address account) public view  returns (uint256) {
        if(block.number - _lastUpdate[account] > _blockNumOfOneDay){
            return 0;
        }
        return _lastEmission[account];
    }


    function lastUpdateOf(address account) public view  returns (uint256) {
        return _lastUpdate[account];
    }

    function totalBalanceOf(address account) public view  returns (uint256) {
        return _totalEmission[account];
    }

    function increaseMetaForestCarbonEmissions(address user, uint256 amount) public onlyAdmin {
       require(block.number - _lastUpdate[user] > _blockNumOfOneDay, "can't increase in limit time");
        _lastUpdate[user] = block.number;
        _lastEmission[user] = amount;
        _totalEmission[user] = _totalEmission[user] + amount;
        emit Increase(user,amount);
    }

    */

    pub fun lastBalanceOf(user: Address):UInt8 {
        let convertedBlockNumber = MetaForestCarbonEmission.blockNumOfOneDay as! UInt8
        if convertedBlockNumber - MetaForestCarbonEmission.lastUpdate[user]! > convertedBlockNumber{
            return 0
        }
        return MetaForestCarbonEmission.lastEmission[user]!
    }

    pub fun lastUpdateOf(user: Address):UInt8{
        return  MetaForestCarbonEmission.lastUpdate[user]!
        
    }
    pub fun totalBalanceOf(user: Address):UInt8  {
        return MetaForestCarbonEmission.totalEmission[user]!
    }


    access(account) fun increaseMetaForestCarbonEmissions(user: Address, amount:UInt8){
        let convertedBlockNumber = MetaForestCarbonEmission.blockNumOfOneDay as! UInt8
        assert(convertedBlockNumber - MetaForestCarbonEmission.lastUpdate[user]! > convertedBlockNumber, message: "can't increase in limit time")
        MetaForestCarbonEmission.lastUpdate[user] = MetaForestCarbonEmission.blockNumOfOneDay as! UInt8
        MetaForestCarbonEmission.lastEmission[user] = amount
        MetaForestCarbonEmission.totalEmission[user] = MetaForestCarbonEmission.totalEmission[user]! + amount

    }




    init(){
        self.totalEmission = {}
        self.lastEmission = {}
        self.lastUpdate = {}
        self.blockNumOfOneDay = getCurrentBlock().id 
    }



  
}