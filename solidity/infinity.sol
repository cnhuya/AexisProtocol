// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.22;

contract Infinity {
    constructor() {}
    
    struct UserStats {
        uint256 points;
        uint256 holderSince;
    }

    uint8 public monthlyInflation = 10; // 0.1%
    uint8 public Fee = 100;

    uint16 pointsForTX = 1;
    uint16 pointsForVolumePercentage = 10000; // 0.01%
    uint16 MinimumValueForHolderDetection = 1;

    // Mapping to store user stats
    mapping(address => UserStats) internal users;

    function getUserStats(address user) public view virtual returns (uint256 points, uint256 holderSince) {
        return (getUserPoints(user), getUserHolderSince(user));
    }

    function getUserPoints(address user) internal view virtual returns (uint256 points) {
        UserStats memory stats = users[user];
        return (stats.points);
    }

    function getUserHolderSince(address user) internal view virtual returns (uint256 holderSince) {
        UserStats memory stats = users[user];
        return (stats.holderSince);
    }

    function getPointsSettings() public view virtual returns (uint16 points_for_transaction, uint16 point_for_volume_percentage, uint16 minimum_holding_for_detection) {
        return (getPointsForTx(), getPointsMinimumHoldingValue(), getpointsForVolumePercentage());
    }

    function getPointsForTx() internal view virtual returns (uint16 points_for_transaction) {
        return (pointsForTX);
    }

    function getPointsMinimumHoldingValue() internal view virtual returns (uint16 minimum_holding_for_detection) {
        return (MinimumValueForHolderDetection);
    }

    function getpointsForVolumePercentage() internal view virtual returns (uint16 point_for_volume_percentage) {
        return (pointsForVolumePercentage);
    }

    function addUserStats(address user, uint256 value) public {
        require(value > 0, 'Invalid value');
        UserStats storage stats = users[user];
        // 1 000 000 / 10 000 = 100 + 1 = 101
        stats.points += value  + pointsForTX;
        if(stats.holderSince == 0){
            require(value >= MinimumValueForHolderDetection);
            uint256 _now = block.timestamp;
            stats.holderSince = _now;
        }
    }
}
