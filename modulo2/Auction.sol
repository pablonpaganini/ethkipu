// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Owner.sol";
import "./Timer.sol";
/** 
 * @title Auction
 * @dev Contract to manage auctions
 */

contract Auction is Owner, Timer {
    uint256 constant DELTA_BID = 5;
    uint256 constant COMISSION = 2;

    event EventNewBid(address indexed sender, uint256 value);
    event EventAuctionClosed();

    bool closedEventSend = false; // Flag 
    address bestBidAddress; // bidder's address with the best bid
    uint256 public minimumBid; // Prevents bids below gas required to withdraw
    mapping(address => uint256) biddersBalances;
    mapping(address => uint256) public bids; 

    modifier auctionIsFinalized {
        require(timerIsFinalized(), "Auction is still open");
        _;
    }

    /**
     * @dev Open the auction
     * @param _minimumBid The minimum amount to place a bid
     * @param _duration Duration of the auction in seconds
     */
    function openAuction(uint256 _minimumBid, uint256 _duration) external isOwner {
        require(!timerIsStarted(), "Auction is already opened");
        require(!timerIsFinalized(), "Auction was closed");
        minimumBid = _minimumBid;
        timerStart(_duration);
    }
    /**
     * @dev Close this auction
     */
    function closeAuction() external isOwner {
        timerFinalize();
        if(!closedEventSend) {
            emit EventAuctionClosed();
            closedEventSend = true;
        }
    }
    /**
     * @dev Place a new bid
     */
    function bid() external payable {
        if(timerIsRunning()) {
            // Bid accepted
            require(msg.value >= minimumBid, "Bid must be greater or equal to the minimum amount.");
            require(msg.value > minimumBidAmount(), "Bid must be greater to the best bid plus 5%.");
            // Add or modify the bidder's bid
            bids[msg.sender] = msg.value;
            // Save address as best bidder address
            bestBidAddress = msg.sender;
            // Extend the auction end time
            timerIncrement(10 minutes); 

            emit EventNewBid(msg.sender, msg.value);
        }
        else {
            require(timerIsStarted(), "Auction is not open yet");
            if(!closedEventSend) {
                emit EventAuctionClosed();
                closedEventSend = true;
            }
        }
        // Increment amount on his balance
        biddersBalances[msg.sender] += msg.value;
    }
    /**
     * @dev Get the actual winner info
     */
    function winner() external view returns (address, uint256) {
        return (bestBidAddress, bids[bestBidAddress]);
    }
    /**
     * @dev Returns bidder's balance
     */
    function getBidderBalance() external view returns (uint256){
        return biddersBalances[msg.sender];
    }
    /**
     * @dev Allows to claim the excess balance from the bid
     */
    function claims() external payable {
        // Everyone can withdraw their excess balance over the bid. 
        uint256 _balance = biddersBalances[msg.sender] - bids[msg.sender];
        require(_balance > 0, "Nothing to claim");
        
        (bool _result, ) = msg.sender.call{value: _balance}("");        
        require(_result, "Error when claims");
        biddersBalances[msg.sender] -= _balance;
    }
    /**
     * @dev Allows owner to refund not winner bids
     * @param _bidder bidder's address to refund
     */
    function refund(address _bidder) external payable isOwner auctionIsFinalized {
        uint256 _balance = calculateRefund(_bidder);
        require(_balance > 0, "Nothing to refund");
        (bool _result, ) = _bidder.call{value: _balance}("");        
        require(_result, "Error when refund");
        biddersBalances[_bidder] = 0;
    }
    /**
     * @dev Withdraw contract's balance
     */
    function withdraw() external payable isOwner auctionIsFinalized {
        (bool _result, ) = msg.sender.call{value: address(this).balance}("");        
        require(_result, "Error when withdraw");
    }
    /**
     * @dev Calculate the minimum amount required for a new bid
     */
    function minimumBidAmount() private view returns (uint256){
        uint256 _bestBidAmount = bids[bestBidAddress];
        return _bestBidAmount + ((_bestBidAmount * 5) / 100);
    }
    /**
     * @dev Calculate amount to refund
     * @param _bidder bidder's address
     */
    function calculateRefund(address _bidder) private view returns (uint256){
        uint256 _amount = biddersBalances[_bidder];
        if(_bidder == bestBidAddress) {
            _amount -= bids[_bidder];
        }
        return _amount - (_amount * COMISSION) / 100;
    }
}