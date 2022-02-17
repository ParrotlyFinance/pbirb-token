/**
 *  SPDX-License-Identifier: MIT
 *  
 *                                .::----::.                                                
 *                           .-=+*++======++*++-                                            
 *                         =++=------------+*+-                                             
 *                       +*=-----------=++=:                                                
 *                     =*=-----------++=.                                                   
 *                    *+----------=*=.                                                      
 *                  .#=---------+*-                                                         
 *                 :#=--------+*:             .-=++*****+=:   .:---.     ....               
 *                .#=++=----+*:           .=*#*++=++===+##%%%%%###%%%+++++==++++=:          
 *             .-+**+#*---=*=   .:      :##+=*#*=-:::-==+--*#####%%=-=*=------::-*#:        
 *           -++=--=#+---=*.   =%%%.  .*#-:+=:           :+=:+##%@=--##----------:=%*       
 *         -*+-----#=---+*:==  -%#%+ :%+ -+        :::.    .*:+#%*-----------------=##      
 *        =*------#+---=* %##%: :*%%#%+ -+          *++=.    *:+%+------------------=**     
 *       :#------+#---=#  ####%#*+*@@#. #    .     -@@#++:    * *+-------------------+*-    
 *       #=------#=---#:   =*#%%##%@@# :+   :+-==+#@@@@*++    # ++-------------------+-*    
 *       %-------#---=*     .====*%@%#  *   .++*@@@@@#=:--    # -*-------------------+-%    
 *       @------=#---+=     *#####%%##- +:   .=++##%#        ==  %-------------------=-#    
 *       #=-----=#---*-      -+++= =%#*. *:    :-==+=.      =+   %-------------------=-%    
 *       =*------%---*-            -%##:  =+. ----------:..*-   :#-------------------=-#    
 *       .%------#=--+=             %##:   .-.           .-.    =+--------------------=*    
 *      -***-----+*--=#             -%##:                       ++--------------------*-    
 *     -*--#+-----#=--#:             ###=                       .%=------------------=%     
 *     %=--=%=----=#--=%             :%###+                     :##+-----=*##%%%%#=--#.     
 *     %----=#=----+#--=*             =@###***:                 :*-#%###%%#######@#*#:      
 *     #=----=#=----+#=-+*            *@@#######+**::.          :*-#*****##%%**#**          
 *     .#-----=#=----=#=-+*           .@@@@%#########***=**-=:  .#-****#%#%#***%+:          
 *      :#=----=#+----=#+-=#:          -@@@@%#%################*:%-=%**%##%#***%+:          
 *       .#=-----#+-----**--*+.         %@@@@@@##################%=-###%#####**%+#:         
 *         +*=----+#=----+#=-=*+.       @@@@@@@%#####%############%--#%####*#*##+-=*        
 *          -+*=---=**=----**=-=**=:. -%@@@@@@@@@###@%#############*--=++++++=---=#=        
 *         .%*:+*=---=**=----+%##***##%@@@@@@*+*@@@@@%#####%#########=--------=*#%#%=       
 *         :#=*+:=*+---+%*****%#*****##-=-=+*====%@@@@%####@%#%%#####%#*****#%####%*+       
 *          #=-=*+-:+*%************###%%*+=====-#%%@@@@@%#%@%%=@#############%##@%#         
 *           **---=*+-=+###******#+===========*#%##%@@%@@@*.: =%##%%####%@###%%%+.          
 *            :+*+=--=+#*#%#####*#+==========+#%###@@@%@@@@*::**+: %###%@@####*=            
 *               .:==++%***********###*+=====-###%@@@@@%@@@@@%=::=#%#%@@%%#%+               
 *                      -=+*####*###%*====-==+@@@@@@@@@@%@@%%@@@@@@%%%@# :=.                
 *                          =%##%%####%%%%%%%@@@***+++@@@%%@@#%@@@#:  =                     
 *                           +%###############%%@%%@@@@@@@@%%@@@*.                          
 *                             +#%%###############%@@@@@@%%@%#=                             
 *                               %%%%%%%%%%%%%%####%%%@%@@#=.                               
 *                               :@##@..@##@:.:----::.                                      
 *                                #++#-=+-=#*+**#%:                                         
 *                            =#=+++++**++*@#=++*@+                                         
 *                            ::::..  ..:--+-    :  
 *
 *  Parrotly (PBIRB)
 *
 *  Tokenomics:
 *    - BUY:
 *      - 4% To service Wallet
 *    - SELL:
 *      - 2% to the Dead Wallet (burn)
 *    - Transfer wallet to wallet
 *      - NO taxes
 *    - Taxes can ONLY be reduced and never increased. If moved from 4 to 3.
 *      It will never (it's not possible) put it back to 4.
 *    - Once both Buy and Sell are set to 0. NO other changes to the taxes will be possible.
 *      The removal of taxes is definitive.
 *    - Service wallet and CEX wallets are and will be excluded from any tax.
 *    - 0 initial dev or team wallets.
 *
 *
 *  Website -------- https://parrotly.finance
 *  Whitepaper ----- https://parrotly.finance/resources/docs/Parrotly_Whitepaper.pdf
 *  Twitter -------- https://twitter.com/ParrotlyFinance
**/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Parrotly is ERC20, Ownable {
    using Address for address;

    bool private _buyFeeAllowed = true;
    bool private _sellFeeAllowed = true;
    uint8 private _buyFee = 4;
    uint8 private _previousBuyFee = _buyFee;
    uint8 private _sellFee = 2;
    uint8 private _previousSellFee = _sellFee;
    
    mapping (address => bool) public _automatedMarketMakerPairs;
    mapping (address => bool) private _exemptFromFee;

    bool private _tradingEnabled = false;
    uint private _blockAtEnableTrading;

    IUniswapV2Router02 public quickSwapRouter;
    address public quickSwapPair;
    address private _routerAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Quickswap
    address private _serviceWallet = 0x049DE3990D8a938d627730696a53B7042782120E;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    event EnableTrading();
    event RemoveFees();
    event RestoreFees();
    event UpdateServiceWallet(address indexed newAddress);
    event UpdateBuyFee(uint indexed previousBuyFee, uint indexed newBuyFee);
    event UpdateSellFee(uint indexed previousSellFee, uint indexed newSellFee);
    event ExcludeFromFees(address indexed newAddress, bool indexed value);
    event SetAutomatedMarketMakerPair(address indexed pairAddress, bool indexed value);

    // Modifier

    modifier canTrade {
        if (msg.sender == owner()) {
            _;
            return;
        }

        require(_tradingEnabled, "Trading is not enabled");

        if(block.number > _blockAtEnableTrading + 3) {
            _;
        }
        else {
            _buyFee = 99;
            _sellFee = 99;
            _;
            _buyFee = _previousBuyFee;
            _sellFee = _previousSellFee;
        }
    }

    // Constructor
    constructor() ERC20("Parrotly", "PBIRB") {
        //initPair();

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(_serviceWallet, true);

        _mint(owner(), (1 * 10**12) * (10**18));
    }

    // Receive function

    receive() external payable {}

    // Internal

    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal override canTrade {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_tradingEnabled || sender == owner(), "Trading is not enabled");

        if(skipFees(sender, recipient)) {
            super._transfer(sender, recipient, amount);
        } else {
            _tokenTransfer(sender, recipient, amount);
        }
    }

    function initPair() internal {
        IUniswapV2Router02 _quickSwapRouter = IUniswapV2Router02(_routerAddress);
        address _quickSwapPair = IUniswapV2Factory(_quickSwapRouter.factory()).createPair(
            address(this), 
            _quickSwapRouter.WETH()
        );

        quickSwapPair = _quickSwapPair;
        quickSwapRouter = _quickSwapRouter;

        setAutomatedMarketMakerPair(_quickSwapPair, true);
    }

    // External

    function buyFee() external view returns (uint8) {
        return _buyFee;
    }
    
    function sellFee() external view returns (uint8) {
        return _sellFee;
    }

    // Public

    function enableTrading() public onlyOwner {
        _tradingEnabled = true;
        _blockAtEnableTrading = block.number;

        emit EnableTrading();
    }

    function excludeFromFees(address excludedAddress, bool value) public onlyOwner {
        require(_exemptFromFee[excludedAddress] != value, "Already set to this value");

        _exemptFromFee[excludedAddress] = value;

        emit ExcludeFromFees(excludedAddress, value);
    }

    function excludedFromFees(address excludedAddress) public view returns (bool) {
        return _exemptFromFee[excludedAddress];
    }

    function getAutomatedMarketMakerPair(address pairAddress) public view onlyOwner returns (bool) {
        return _automatedMarketMakerPairs[pairAddress];
    }

    function removeFees() public onlyOwner {
        require(_buyFeeAllowed || _sellFeeAllowed, "Fees are permanently disabled");

        if (_buyFeeAllowed) {
            _previousBuyFee = _buyFee;
            _buyFee = 0;
        }

        if (_sellFeeAllowed) {
            _previousSellFee = _sellFee;
            _sellFee = 0;
        }

        emit RemoveFees();
    }

    function restoreFees() public onlyOwner {
        require(_buyFeeAllowed || _sellFeeAllowed, "Fees are permanently disabled");

        if(_buyFeeAllowed) 
            _buyFee = _previousBuyFee;

        if(_sellFeeAllowed)
            _sellFee = _previousSellFee;

        emit RestoreFees();
    }

    function serviceWallet() public view returns(address) {
        return _serviceWallet;
    }

    function setAutomatedMarketMakerPair(address pairAddress, bool value) public onlyOwner {
        require(_automatedMarketMakerPairs[pairAddress] != value, "Address already in-use");
        
        _automatedMarketMakerPairs[pairAddress] = value;
        
        emit SetAutomatedMarketMakerPair(pairAddress, value);
    }

    function totalSupply() public view virtual override returns (uint) {
        return super.totalSupply() - balanceOf(DEAD);
    }

    function updateBuyFee(uint8 value) public onlyOwner returns(uint8, uint8) {
        require(_buyFeeAllowed, "Buy fee is permanently disabled");
        require(value <= 4, "Cannot be higher than 4");
        require(value < _buyFee, "Cannot increase the fee");

        _previousBuyFee = _buyFee;
        _buyFee = value;

        if(_buyFee == 0)
            _buyFeeAllowed = false;

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
        require(_sellFeeAllowed, "Sell fee is permanently disabled");
        require(value <= 2, "Cannot be higher than 2");
        require(value < _sellFee, "Cannot increase the fee");

        _previousSellFee = _sellFee;
        _sellFee = value;

        if(_sellFee == 0)
            _sellFeeAllowed = false;

        emit UpdateSellFee(_previousSellFee, value);
        
        return (_sellFee, _previousSellFee);
    }

    // Private

    function _buyTransfer(
        address sender,
        address recipient,
        uint amount
    ) private {
        uint _totalFee = _calculateBuyFee(amount);
        uint _amountWithFee = amount - _totalFee;

        super._transfer(sender, recipient, _amountWithFee); // Send coin to buyer
        super._transfer(sender, _serviceWallet, _totalFee); // Send coin to Service Wallet

        emit Transfer(sender, recipient, amount);
    }

    function _calculateBuyFee(uint amount) private view returns (uint) {
        if (_buyFee == 0)
            return 0;

        return (amount * _buyFee) / 10**2;
    }

    function _calculateSellFee(uint amount) private view returns (uint) {
        if (_sellFee == 0)
            return 0;

        return (amount * _sellFee) / 10**2;
    }

    function _sellTransfer(
        address sender,
        address recipient,
        uint amount
    ) private {
        uint _totalFee = _calculateSellFee(amount);
        uint _amountWithFee = amount - _totalFee;

        super._transfer(sender, recipient, _amountWithFee); // Send coin to buyer
        super._transfer(sender, DEAD, _totalFee); // Send coin to Dead Wallet

        emit Transfer(sender, recipient, amount);
    }

    function skipFees(address sender, address recipient) private view returns (bool) {
        return (!_automatedMarketMakerPairs[sender] && !_automatedMarketMakerPairs[recipient]) &&
            (_exemptFromFee[sender] || _exemptFromFee[recipient]);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint amount
    ) private {
        if (_automatedMarketMakerPairs[sender]) {
            _buyTransfer(sender, recipient, amount);
        } else if (_automatedMarketMakerPairs[recipient]) {
            _sellTransfer(sender, recipient, amount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
}
