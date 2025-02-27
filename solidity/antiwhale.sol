// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.22;



contract AntiWhale{
    // Declare abc as a state variable


    uint256 _initialSupply;
    uint8 _maxTransferPercentage = 50; // 0.5;
    uint8 month = 1;
    uint256 _start;
    uint8 cooldown = 60;
    uint16 public snipeFee = 1000; // 10%
    uint256 previousDiff;

    constructor(uint256 _initialSupply_) { // Constructor now takes the Aexis contract address
        _initialSupply = _initialSupply_; // Instantiate Aexis
        _start = block.timestamp;
    }
    function initialSupply() public view virtual returns (uint256) {
        return _initialSupply;
    }

    function viewSeason() public view virtual returns (uint8) {
        return month;
    }

    function viewTransferPercentage() public view virtual returns (uint8) {
        return _maxTransferPercentage + (viewSeason() * 50);
        // 50 + (1*50) = 100 (1%)
    }


    function viewCooldown() public view virtual returns (uint8) {
        return cooldown - (viewSeason() * 5);
        // 60 - (1*5) = 55 minutes
    }

    /*
    @notice If we call antiwhale() in the constructor, we can add an extra condition that will ensure
            that antiwhale() is only called once per season (i.e., at the start of a new season)

            current set limits are:
            Maximum Anti-Whale Season Limit: 12 months

            Increase Transfer Percentage: 0.5%
            Starting Maximum Transfer Percentage: 1%
            Ending Maximum Transfer Percentage: 6% (in 1 tx)
            fee: 5% for every 1% over the limit

            (e.g. User sends over 3% of total supply in 1 tx,
            the receiver only receives 90% of the amount, because of 2*5 = 10% burn fee.
            This would then equal to actually only 2,7% of total supply sent, and 0,3% burned.)



            Decrease Transfer Cooldown: 5 minutes
            Starting Transfer Cooldown: 55 minutes
            Ending Transfer Cooldown: 0 minutes
            Fee: 0.1% for every minute over the limit.

            (e.g. User makes 3 transfers with a 2 minutes delay in between with a transfer cooldown of 10 minutes.
            This would make a difference of 8 minutes, which would equal to 0,8% burn fee of the sent amount, for each TX.)



            Decrease Snipe Fee per hour: 2%
            Starting Snipe Fee: 10% 
            Duration: 5 hours

            
    */

    function snipe() public {
        uint256 _nowInHours = block.timestamp / 3600;
        uint256 _startInHours = _start / 3600;
        uint256 Diff = _nowInHours - _startInHours;
        uint16 prevSnipeFee = snipeFee;
        require(prevSnipeFee != snipeFee, "Snipe Fee is the same");
        snipeFee = snipeFee - (uint16(Diff)*200);
        // 1000 - 400 = 600 (6%) after 2 hours
    }

    function season() public {
        require(viewSeason() <= 10, "Maximum Season Limit Reached");
        uint256 _now = block.timestamp;
        require((_now / 2592000) > (_start / 2592000));
        month = month + 1;
    }
} 