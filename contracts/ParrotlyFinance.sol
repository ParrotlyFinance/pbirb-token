// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract ParrotlyFinance is IERC20, IERC20Metadata, Context, Ownable {
    using Address for address;

    // Basic Setup 
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1 * 10**12 * 10**_decimals;
    string private _name = "ParrotlyFinance";
    string private _symbol = "PBIRBTEST26";

    uint8 public _buyFee = 4;
    uint8 private _previousBuyFee = _buyFee;
    uint8 public _sellFee = 2;
    uint8 private _previousSellFee = _sellFee;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private _excludedFromFees;

    IUniswapV2Router02 private _quickSwapRouter;
    address private _quickSwapPair;
    address private constant _quickSwapRouterAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Quickswap
    // address private constant _quickSwapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap
    address public immutable _deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public _serviceWallet = 0x049DE3990D8a938d627730696a53B7042782120E;

    event RemoveFees();
    event RestoreFees();
    event UpdateServiceWallet(address indexed newAddress);
    event UpdateBuyFee(uint256 indexed previousBuyFee, uint256 indexed newBuyFee);
    event UpdateSellFee(uint256 indexed previousSellFee, uint256 indexed newSellFee);
    event ExcludeFromFees(address newAdress, bool value);

    // Constructor
    constructor() {
        _quickSwapRouter = IUniswapV2Router02(_quickSwapRouterAddress);
        _quickSwapPair = IUniswapV2Factory(_quickSwapRouter.factory())
            .createPair(address(this), _quickSwapRouter.WETH());

        _excludedFromFees[_msgSender()] = true;
        _excludedFromFees[address(this)] = true;
        _excludedFromFees[_serviceWallet] = true;
        _excludedFromFees[_quickSwapRouterAddress] = true;

        _balances[_msgSender()] = _totalSupply; // 1.000.000.000.000 (1T)

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Receive function

    receive() external payable {}

    // External

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _approve(spender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(recipient, amount);

        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // Public

    function buyFee() public view returns (uint8) {
        return _buyFee;
    }

    function excludeFromFees(address excludedAddress, bool value) public onlyOwner {
        require(_excludedFromFees[excludedAddress] != value, "This address is already set with this value.");

        _excludedFromFees[excludedAddress] = value;

        emit ExcludeFromFees(excludedAddress, value);
    }

    function excludedFromFees(address wallet) public view returns(bool) {
        return _excludedFromFees[wallet];
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

    function updateBuyFee(uint8 value) public onlyOwner {
        require(value <= 4, "Buy fee cannot be higher than 4");
        require(value < _buyFee, "You cannot increase the fee");

        _previousBuyFee = _buyFee;
        _buyFee = value;

        emit UpdateBuyFee(_previousBuyFee, value);
    }

    function updateServiceWallet(address newServiceWallet) public onlyOwner {
        require(_serviceWallet != newServiceWallet, "Same address");

        _serviceWallet = newServiceWallet;

        emit UpdateServiceWallet(newServiceWallet);
    }

    function updateSellFee(uint8 value) public onlyOwner {
        require(value <= 2, "Buy fee cannot be higher than 4");
        require(value < _sellFee, "You cannot increase the fee");

        _previousSellFee = _sellFee;
        _sellFee = value;

        emit UpdateSellFee(_previousSellFee, value);
    }

    // Private

    function _transfer(
        address recipient,
        uint256 amount
    ) private {
        uint256 senderBalance = _balances[_msgSender()];
        require(
            senderBalance >= amount,
            "Transfer exceeds balance"
        );
        require(
            recipient != address(0),
            "transfer from the zero address"
        );
        require(
            _msgSender() != address(0), 
            "transfer to the zero address"
        );
        require(
            amount > 0, 
            "Transfer amount must be greater than zero"
        );

        if(_excludedFromFees[_msgSender()] || _excludedFromFees[recipient]) {
            _feelessTransfer(recipient, amount);
        } else {
            _tokenTransfer(recipient, amount);
        }
    }

    function _tokenTransfer(
        address recipient,
        uint256 amount
    ) private {
        if (_msgSender() == _quickSwapPair) {
            _buyTransfert(recipient, amount);
        } else if (recipient == _quickSwapPair) {
            _sellTransfer(recipient, amount);
        } else {
            _feelessTransfer(recipient, amount);
        }
    }

    function _buyTransfert(
        address recipient,
        uint256 amount
    ) private {
        uint256 _totalFee = _calculateBuyFee(amount);
        uint256 _amountWithFee = amount - _totalFee;

        _balances[_msgSender()] -= amount; // Remove Token from Sender
        _balances[recipient] += _amountWithFee; // Add Token to recipient
        _balances[_serviceWallet] += _totalFee; // Add fee to the service wallet

        emit Transfer(_msgSender(), recipient, _amountWithFee);
    }

    function _sellTransfer(
        address recipient,
        uint256 amount
    ) private {
        uint256 _totalFee = _calculateSellFee(amount);
        uint256 _amountWithFee = amount - _totalFee;

        _balances[_msgSender()] -= amount; // Remove Token from Sender
        _balances[recipient] += _amountWithFee; // Add  Token to recipient
        _totalSupply -= _totalFee; // Reduce total supply to remove coin

        emit Transfer(_msgSender(), recipient, _amountWithFee);
    }

    function _feelessTransfer(
        address recipient,
        uint256 amount
    ) private {
        _balances[_msgSender()] -= amount; // Remove Token from Sender
        _balances[recipient] += amount;

        emit Transfer(_msgSender(), recipient, amount);
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
}
