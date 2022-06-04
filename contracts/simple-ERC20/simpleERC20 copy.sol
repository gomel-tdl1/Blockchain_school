// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract SimpleERC20 is ERC20, Ownable {
    uint256 public timeToVote;
    uint256 public price;

    uint256 private _startVotingTimestamp;
    mapping(uint256 => uint256) private _votesByOption;

    constructor(uint256 _timeToVote, uint256 _price, uint256 initialSupply, string memory _name, string memory _symbol) public ERC20(_name, _symbol) {
        timeToVote = _timeToVote;
        price = _price;
        _mint(address(this), initialSupply);
    }

    function calculateBalancePercents(uint256 _balance) public view returns(uint256) {
        return _balance / totalSupply() * 10000;
    }

    function _clearVoting() private {
        for(uint256 i = 0; i <= 2; i++) {
            _votesByOption[i] = 0;
        }
        _startVotingTimestamp = 0;
    }

    //// @notice 0 stay current price
    //// @notice 1 pump price on 10%
    //// @notice 2 dump price on 10%
    function votePriceChange(uint256 _option) external {
        require(_option < 3 && _option >= 0, "invalid option");

        uint256 balancePercent = calculateBalancePercents(balanceOf(msg.sender));
        uint256 endVotingTimestamp = _startVotingTimestamp + timeToVote;

        require(balancePercent >= 500, "balance percent < 5%");

        if(_startVotingTimestamp == 0) {
            _startVotingTimestamp = block.timestamp;
        }

        require(endVotingTimestamp > block.timestamp && _startVotingTimestamp < block.timestamp, "!voting" );

        _votesByOption[_option]++;
    }

    function calculateNewPrice(uint256 _option) public view returns(uint256){
        uint256 tenPercentsOfPrice = price * 1000 / 10000;
        if(_option == 0) return price;
        if(_option == 1) return price + tenPercentsOfPrice;
        if(_option == 2) return price - tenPercentsOfPrice;
    }

    function _changePrice() private {
        uint256 highOption = 0;

        uint256 highVoutes = 0;
        for(uint256 i = 0; i <= 2; i++) {
            if(_votesByOption[i] > highVoutes){
                highOption = i;
                highVoutes = _votesByOption[i];
            }
        }

        price = calculateNewPrice(highOption);
    }

    function changePriceAndClearVoting() external{
        require(_startVotingTimestamp + timeToVote < block.timestamp, "!end");

       _changePrice();

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