// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract SimpleERC20 is ERC20, Ownable {
    uint64 public timeToVote;
    uint256 public price;

    mapping(address => uint256) private _votedPrices;
    address[] private _voters;
    uint64 private _startVotingTimestamp;

    constructor(uint64 _timeToVote, uint256 _price, uint256 initialSupply, string memory _name, string memory _symbol) public ERC20(_name, _symbol) {
        timeToVote = _timeToVote;
        price = _price;
        _mint(address(this), initialSupply);
    }

    function calculateBalancePercents(uint256 _balance) public view returns(uint256) {
        return _balance / totalSupply() * 10000;
    }

    function _clearVoting() private {
        for(uint16 i = 0; i < _voters.length; i++) {
            address voter = _voters[i];
            _votedPrices[voter] = 0;
        }
        _voters = new address[](0);
        _startVotingTimestamp = 0;
    }

    function startVoting() external onlyOwner() {
        _startVotingTimestamp = uint64(block.timestamp);
    }

    function votePriceChange(uint256 _price) external {
        require(_price > 0, "price = 0");
        require(_startVotingTimestamp == 0, "!voting");

        uint256 balancePercent = calculateBalancePercents(balanceOf(msg.sender));
        uint64 endVotingTimestamp = _startVotingTimestamp + timeToVote;

        require(balancePercent >= 500, "balance percent < 5%");
        require(endVotingTimestamp > uint64(block.timestamp) && _startVotingTimestamp < uint64(block.timestamp), "!voting" );

        _votedPrices[msg.sender] = _price;
        _voters.push(msg.sender);
    }

    function changePriceAndClearVoting() external onlyOwner(){
        require(_startVotingTimestamp + timeToVote < uint64(block.timestamp), "!end");

        address highestHolder;

        uint256 highestBalance = 0;
        for(uint16 i = 0; i < _voters.length; i++) {
            address voter = _voters[i];
            uint256 voterBalance = balanceOf(voter);
            if(voterBalance > highestBalance){
                highestBalance = voterBalance;
                highestHolder = voter;
            }
        }

        price = _votedPrices[highestHolder];

        _clearVoting();
    }

    function cancelVoting() external onlyOwner() {
        _clearVoting();
    }

    function buy() external payable {
        uint256 amountForTransfer = (msg.value / price) * 10 ** 18;
        bool transferBool = transferFrom(address(this), msg.sender, amountForTransfer);
        require(transferBool);
    }

    function sell(uint256 _amount) external {
        uint256 amountForSend = (_amount * price) / 10 ** 18;
        payable(msg.sender).transfer(amountForSend);
    }
}