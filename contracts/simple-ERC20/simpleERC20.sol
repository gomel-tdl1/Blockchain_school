// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

struct Vote {
    address votingOwner;
    uint256 votingNumber;
    uint256 votedAgree;
    uint256 votedDesagree;
    uint256 newPrice;
}

contract SimpleERC20 is ERC20, Ownable {
    uint256 public timeToVote;
    uint256 public price;
    uint256 public prevVotingNumber;
    Vote public currentVoting;

    mapping(address => mapping(uint256 => bool)) private _isVoterVoted;

    uint256 private _startVotingTimestamp;

    constructor(uint256 _timeToVote, uint256 _price, uint256 initialSupply, string memory _name, string memory _symbol) public ERC20(_name, _symbol) {
        timeToVote = _timeToVote;
        price = _price;
        prevVotingNumber = 0;
        _mint(address(this), initialSupply);
    }

    modifier onlyFivePercentsHolder() {
        uint256 balancePercent = calculateBalancePercents(balanceOf(msg.sender));
        require(balancePercent >= 500, "balance percent < 5%");

        _;
    }

    function calculateBalancePercents(uint256 _balance) public view returns(uint256) {
        return _balance / totalSupply() * 10000;
    }

    function _clearVoting() private {
        _startVotingTimestamp = 0;
    }

    function startVoting(uint256 _price) external onlyFivePercentsHolder(){
        require(_startVotingTimestamp != 0, "voting already started");
        ++prevVotingNumber;
        _startVotingTimestamp = uint64(block.timestamp);
        currentVoting = Vote(msg.sender, prevVotingNumber, 0, 0, _price);
    }

    function votePriceChange(bool _agreement) external onlyFivePercentsHolder(){
        require(_startVotingTimestamp == 0, "!voting");
        require(!_isVoterVoted[msg.sender][currentVoting.votingNumber], "user already voted");

        uint256 endVotingTimestamp = _startVotingTimestamp + timeToVote;
        require(endVotingTimestamp > block.timestamp && _startVotingTimestamp < block.timestamp, "!voting" );

        if(_agreement) currentVoting.votedAgree++;
        if(!_agreement) currentVoting.votedDesagree++;
        _isVoterVoted[msg.sender][currentVoting.votingNumber] = true;
    }

    function changePriceAndClearVoting() external {
        require(_startVotingTimestamp + timeToVote < block.timestamp, "!end");

        if(currentVoting.votedAgree > currentVoting.votedDesagree){
            price = currentVoting.newPrice;
        }

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