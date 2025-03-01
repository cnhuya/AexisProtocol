// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.22;

    /**
    @notice If we call antiwhale() in the constructor, we can add an extra condition that will ensure
     *      that antiwhale() is only called once per season (i.e., at the start of a new season)
     
            [=  ANTI-WHALE-PERIOD FACTOR  =]
            Maximum Anti-Whale Season Limit: 12 months

            [=  ANTI-WHALE-MAX-DUMP FACTOR  =]
            Increase Transfer Percentage: 0.5%
            Starting Maximum Transfer Percentage: 1%
            Ending Maximum Transfer Percentage: 6% (in 1 tx)
            fee: 5% for every 1% over the limit
            ------------------------------------------
            (e.g. User sends over 3% of total supply in 1 tx,
            the receiver only receives 90% of the amount, because of 2*5 = 10% burn fee.
            This would then equal to actually only 2,7% of total supply sent, and 0,3% burned.)

            [=  ANTI-WHALE-SOFT-DUMP FACTOR  =]
            Decrease Transfer Cooldown: 5 minutes
            Starting Transfer Cooldown: 55 minutes
            Ending Transfer Cooldown: 0 minutes
            Fee: 0.1% for every minute over the limit.
            ------------------------------------------
            (e.g. User makes 3 transfers with a 2 minutes delay in between with a transfer cooldown of 10 minutes.
            This would make a difference of 8 minutes, which would equal to 0,8% burn fee of the sent amount, for each TX.)

            [=  ANTI-SNIPE FACTOR  =]
            Decrease Snipe Fee per hour: 2%
            Starting Snipe Fee: 10% 
            Duration: 5 hours
    */



contract AntiWhale{

    // Initial Variables
    uint256 _start;
    uint256 _initialSupply;
    uint16 maxSeasons = 10;
    // Anti-Whale-Transfers Variables
    uint8 _maxTransferPercentage = 50; // 0.5;
    // Season
    uint8 _season = 1;
    // Anti-Snipe Variables
    uint16 snipeFeeReduction;
    uint16 snipeFee = 1000; // 10%
    uint16 visibleSnipeFee;
    // Anti-Tx-Spam Variables, this is because whales could just split 1 big chunk into smaller transactions
    uint8 cooldown = 30; // in minutes
   // uint256 previousDiff;

    constructor() { 
        _start = block.timestamp;
        visibleSnipeFee = snipeFee;
    }

    function viewSeason() public view virtual returns (uint8) {
        return _season;
    }

    function viewTransferPercentage() public view virtual returns (uint8) {
        return _maxTransferPercentage + (viewSeason() * 50);
        // 50 + (1*50) = 100 (1%)
    }

    function viewSnipeFee() public view virtual returns (uint16) {
        uint256 _nowInHours = block.timestamp / 1;
        uint256 _startInHours = _start / 1;
        uint256 Diff = _nowInHours - _startInHours;
        uint16 returnValue;
        if(Diff >= 5){
            returnValue = 0;    
        }
        else{
            returnValue = snipeFee - (uint16(Diff)*200); 
        }
        return returnValue;
    }

    function viewCooldown() public view virtual returns (uint8) {
        uint8 cdr = cooldown - (viewSeason() * 3);
        uint8 returnValue;
        if(cooldown <= 0){
            returnValue = 0;
        }
        else {
            returnValue = cdr;
        }
        return returnValue;
    }

    /**
     * @dev Anti-snipe feature, this feature is disabled after few minutes/hours.
     * Just a preventive settings for either bots or market manipulators such as insiders.
     * 
     *
     * Calculations:
     *  - Snipe Fee starts at 10%,
     *  - It gets reduced by 2% every hour, until reaching the end of transfer cooldown (0 minutes).
     *  - So after 5 hours there is 0 Snipe fee, and this function is completly skipped.
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `value`.
     */
    function snipe() internal  {
        uint256 _nowInHours = block.timestamp / 1;
        uint256 _startInHours = _start / 1;
        uint256 Diff = _nowInHours - _startInHours;
        if(Diff >= 5){
            visibleSnipeFee = 0;
        }
        else{
            uint16 prevSnipeFee = snipeFee;
            visibleSnipeFee = snipeFee - (uint16(Diff)*200); 
            require(prevSnipeFee != visibleSnipeFee, "Snipe Fee is the same");
        }

        // 1000 - 400 = 600 (6%) after 2 hours
    }

    function season() public {
        require(viewSeason() <= maxSeasons, "Maximum Season Limit Reached");
        uint256 _now = block.timestamp;
        require((_now / 2592000) > (_start / 2592000), "Time not passed for new season yet");
        _season = _season + 1;
    }

} 
