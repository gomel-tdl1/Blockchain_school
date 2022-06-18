// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

struct Vote {
    address votingOwner;
    uint256 votingNumber;
    uint256 votedAgree;
    uint256 votedDesagree;
    uint256 newPrice;
}

contract SimpleERC20 is ERC20, Ownable, ReentrancyGuard {
    uint256 public timeToVote;
    uint256 public price;
    uint256 public prevVotingNumber;
    Vote public currentVoting;

    mapping(address => mapping(uint256 => bool)) private _isVoterVoted;

    uint256 public startVotingTimestamp;

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
        return _balance * 10000 / totalSupply();
    }

    function _clearVoting() private {
        startVotingTimestamp = 0;
    }

    function startVoting(uint256 _price) external onlyFivePercentsHolder(){
        require(startVotingTimestamp == 0, "voting already started");
        ++prevVotingNumber;
        startVotingTimestamp = block.timestamp;
        currentVoting = Vote(msg.sender, prevVotingNumber, 0, 0, _price);
    }

    function votePriceChange(bool _agreement) external onlyFivePercentsHolder(){
        require(startVotingTimestamp != 0, "!voting");
        require(currentVoting.votingOwner != msg.sender, "owner");
        require(!_isVoterVoted[msg.sender][currentVoting.votingNumber], "user already voted");

        uint256 endVotingTimestamp = startVotingTimestamp + timeToVote;
        require(endVotingTimestamp > block.timestamp && startVotingTimestamp < block.timestamp, "!voting" );

        if(_agreement) currentVoting.votedAgree++;
        if(!_agreement) currentVoting.votedDesagree++;
        _isVoterVoted[msg.sender][currentVoting.votingNumber] = true;
    }

    function changePriceAndClearVoting() external {
        require(startVotingTimestamp + timeToVote < block.timestamp, "!end");

        if(currentVoting.votedAgree > currentVoting.votedDesagree){
            price = currentVoting.newPrice;
        }

        _clearVoting();
    }

    function cancelVoting() external onlyOwner() {
        _clearVoting();
    }

    function buy() external payable nonReentrant() {
        uint256 amountForTransfer = (msg.value / price) * 10 ** 18;
        bool transferBool = this.transfer(msg.sender, amountForTransfer);
        require(transferBool);
    }

    function sell(uint256 _amount) external nonReentrant(){
        bool transferBool = transfer(address(this), _amount);
        require(transferBool);

        uint256 amountForSend = (_amount * price) / 10 ** 18;
        payable(msg.sender).transfer(amountForSend);
    }
}