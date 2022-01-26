// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract ParrotlyFinance is IERC20, Context, Ownable {
    using Address for address;

    // Basic Setup 
    uint8 private _decimals = 9;
    uint256 private _totalSupply = (1 * 10**12) * (10**_decimals);
    string private _name = "ParrotlyFinance";
    string private _symbol = "PBIRB";

    uint8 public _buyFee = 4;
    uint8 private _previousBuyFee = _buyFee;
    uint8 public _sellFee = 2;
    uint8 private _previousSellFee = _sellFee;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping (address => bool) public _automatedMarketMakerPairs;
    mapping (address => bool) private _exemptFromFee;

    IUniswapV2Router02 public _quickSwapRouter;
    address public _quickSwapPair;
    address private _routerAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Quickswap
    // address private constant _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap
    address private _serviceWallet = 0x049DE3990D8a938d627730696a53B7042782120E;

    event RemoveFees();
    event RestoreFees();
    event UpdateServiceWallet(address indexed newAddress);
    event UpdateBuyFee(uint256 indexed previousBuyFee, uint256 indexed newBuyFee);
    event UpdateSellFee(uint256 indexed previousSellFee, uint256 indexed newSellFee);
    event ExcludeFromFees(address indexed newAdress, bool indexed value);
    event SetAutomatedMarketMakerPair(address indexed pairAddress, bool indexed value);

    // Constructor
    constructor() {
        _quickSwapRouter = IUniswapV2Router02(_routerAddress);
        _quickSwapPair = IUniswapV2Factory(_quickSwapRouter.factory()).createPair(
            address(this), 
            _quickSwapRouter.WETH()
        );

        _setAutomatedMarketMakerPair(address(_quickSwapPair), true);

        _exemptFromFee[_msgSender()] = true;
        _exemptFromFee[address(this)] = true;
        _exemptFromFee[_serviceWallet] = true;

        _balances[_msgSender()] = _totalSupply; // 1.000.000.000.000 (1T)

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Receive function

    receive() external payable {}

    // External

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function isFeeExempt(address wallet) external view returns(bool) {
        return _exemptFromFee[wallet];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function setAutomatedMarketMakerPair(address newPair, bool value) external onlyOwner {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    // Public

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function buyFee() public view returns (uint8) {
        return _buyFee;
    }

    function excludeFromFees(address excludedAddress, bool value) public onlyOwner {
        require(_exemptFromFee[excludedAddress] != value, "Already set to this value");

        _exemptFromFee[excludedAddress] = value;

        emit ExcludeFromFees(excludedAddress, value);
    }

    function removeFees() public onlyOwner {
        if (_buyFee == 0 && _sellFee == 0) 
            return;

        _previousBuyFee = _buyFee;
        _previousSellFee = _sellFee;

        _buyFee = 0;
        _sellFee = 0;

        emit RemoveFees();
    }

    function restoreFees() public onlyOwner {
        require(_buyFee != 0 && _sellFee != 0, "Cannot restore when fees are 0");

        _buyFee = _previousBuyFee;
        _sellFee = _previousSellFee;

        emit RestoreFees();
    }

    function sellFee() public view returns (uint8) {
        return _sellFee;
    }

    function serviceWallet() public view returns(address) {
        return _serviceWallet;
    }

    function updateBuyFee(uint8 value) public onlyOwner returns(uint8, uint8) {
        require(value <= 4, "Cannot be higher than 4");
        require(value < _buyFee, "Cannot increase the fee");

        _previousBuyFee = _buyFee;
        _buyFee = value;

        emit UpdateBuyFee(_previousBuyFee, value);

        return (_buyFee, _previousBuyFee);
    }

    function updateServiceWallet(address newServiceWallet) public onlyOwner {
        require(_serviceWallet != newServiceWallet, "Address is already in-use");

        _exemptFromFee[_serviceWallet] = false; // Restore fee for old Service Wallet
        _exemptFromFee[newServiceWallet] = true; // Exclude new Service Wallet

        _serviceWallet = newServiceWallet;

        emit UpdateServiceWallet(newServiceWallet);
    }

    function updateSellFee(uint8 value) public onlyOwner returns(uint8, uint8) {
        require(value <= 2, "Cannot be higher than 2%");
        require(value < _sellFee, "Cannot increase the fee");

        _previousSellFee = _sellFee;
        _sellFee = value;

        emit UpdateSellFee(_previousSellFee, value);
        
        return (_sellFee, _previousSellFee);
    }

    // Internal

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Private

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        if(skipTax(sender, recipient)) {
            _feelessTransfer(sender, recipient, amount);
        } else {
            _tokenTransfer(sender, recipient, amount);
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (_automatedMarketMakerPairs[sender]) {
            _buyTransfert(sender, recipient, amount);
        } else if (_automatedMarketMakerPairs[recipient]) {
            _sellTransfer(sender, recipient, amount);
        } else {
            _feelessTransfer(sender, recipient, amount);
        }
    }

    function _buyTransfert(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 _totalFee = _calculateBuyFee(amount);
        uint256 _amountWithFee = amount - _totalFee;

        _balances[sender] -= amount; // Remove Token from Sender
        _balances[recipient] += _amountWithFee; // Add Token to recipient
        _balances[_serviceWallet] += _totalFee; // Add fee to the service wallet

        emit Transfer(sender, recipient, _amountWithFee);
    }

    function _sellTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 _totalFee = _calculateSellFee(amount);
        uint256 _amountWithFee = amount - _totalFee;

        _balances[sender] -= amount; // Remove Token from Sender
        _balances[recipient] += _amountWithFee; // Add  Token to recipient
        _totalSupply -= _totalFee; // Reduce total supply to remove coin

        emit Transfer(sender, recipient, _amountWithFee);
    }

    function _setAutomatedMarketMakerPair(address pairAddress, bool value) private {
        require(_automatedMarketMakerPairs[pairAddress] != value, "Address already in-use");
        _automatedMarketMakerPairs[pairAddress] = value;

        emit SetAutomatedMarketMakerPair(pairAddress, value);
    }

    function _feelessTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] -= amount; // Remove Token from Sender
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _calculateBuyFee(uint256 amount) private view returns (uint256) {
        if (_buyFee == 0)
            return 0;

        return (amount * _buyFee) / 10**2;
    }

    function _calculateSellFee(uint256 amount) private view returns (uint256) {
        if (_sellFee == 0)
            return 0;

        return (amount * _sellFee) / 10**2;
    }

    function skipTax(address sender, address recipient) private view returns (bool) {
        return (!_automatedMarketMakerPairs[sender] && !_automatedMarketMakerPairs[recipient]) &&
            (_exemptFromFee[sender] || _exemptFromFee[recipient]);
    }
}
