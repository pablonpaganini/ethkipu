// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Timer
 * @dev Contract to manage timers
 */
contract Timer {
    uint256 timer;
    /**
     * @dev Start a timer
     * @param _additionalSeconds Additional seconds to add to timer
     */
    function timerStart(uint256 _additionalSeconds) internal {
        timer = block.timestamp + _additionalSeconds;
    }
    /**
     * @dev Check if timer is running
     */
    function timerIsStarted() internal view returns(bool) {
        return (timer != 0);
    }
    /**
     * @dev Check if timer is finalized
     */
    function timerIsFinalized() internal view returns(bool) {
        return timerIsStarted() && (timer < block.timestamp);
    }
    /**
     * @dev Check if timer is started
     */
    function timerIsRunning() internal view returns(bool) {
        return timerIsStarted() && (timer >= block.timestamp);
    }
    /**
     * @dev Finalize timer
     */
    function timerFinalize() internal {
        timer = block.timestamp - 1; 
    }
    /**
     * @dev Increment timer by _seconds
     */
    function timerIncrement(uint256 _seconds) internal {
        timer += _seconds;
    }
}