// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.22;

contract Time {
    constructor() {}
    
    uint256 public minute = 60;
    uint256 public hour = 3600;
    uint256 public day = 86400;
    uint256 public week = 604800;
    uint256 public month = 25920000;
    uint256 public year = 31104000;

    /**
     * @dev A function, which returns all the convert ratios .
     *
     * Returns:
     * `uint256` minute:
     * `uint256` hour:
     * `uint256` day:
     * `uint256` week:
     * `uint256` month:
     * `uint256` year:
     */
    function convertRatios() public view virtual returns (uint256 _minute, uint256 _hour,uint256 _day,uint256 _week,uint256 _month, uint256 _year) {
        return (minute, hour, day, week, month, year);
    }


    /**
     * @dev A function, which returns the current Unix time epoch in seconds .
     *
     * Return value is `uint256`:
     */
    function Now() public view virtual returns (uint256 unixEpoch) {
        return (block.timestamp);
    }

    /**
     * @dev A function, which returns the current Unix time epoch in minutes .
     *
     * Return value is `uint256`:
     */
    function NowInMinutes() public view virtual returns (uint256 unixEpoch) {
        return (block.timestamp / minute);
    }

    /**
     * @dev A function, which returns the current Unix time epoch in hours .
     *
     * Return value is `uint128`:
     */
    function NowInHours() public view virtual returns (uint128 unixEpoch) {
        return uint128(block.timestamp / hour);
    }

    /**
     * @dev A function, which returns the current Unix time epoch in minutes .
     *
     * Return value is `uint64`:
     */
    function NowInDays() public view virtual returns (uint64 unixEpoch) {
        return uint64(block.timestamp / day);
    }


    /**
     * @dev A function, which returns the current Unix time epoch in minutes .
     *
     * Return value is `uint32`:
     */
    function NowInWeeks() public view virtual returns (uint32 unixEpoch) {
        return uint32(block.timestamp / week);
    }

    /**
     * @dev A function, which returns the current Unix time epoch in minutes .
     *
     * Return value is `uint16`:
     */
    function NowInMonths() public view virtual returns (uint16 unixEpoch) {
        return uint16(block.timestamp / month);
    }

    /**
     * @dev A function, which returns the current Unix time epoch in minutes .
     *
     * Return value is `uint8`:
     */
    function NowInYears() public view virtual returns (uint8 unixEpoch) {
        return uint8(block.timestamp / year);
    }

}
