// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

contract TokenSwap is ReentrancyGuard, Ownable {
    mapping(string => IERC20Extended) public tokens;
    mapping(bytes32 => uint256) public exchangeRates;

    event TokenSwapped(
        address indexed user,
        string fromSymbol,
        string toSymbol,
        uint256 fromAmount,
        uint256 toAmount
    );

    event TokenAddressSet(string symbol, address tokenAddress);
    event ExchangeRateSet(string from, string to, uint256 rate);
    event TokenWithdrawn(address token, uint256 amount);

constructor () Ownable(msg.sender) {

}


    function setTokenAddress(string memory symbol, address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        tokens[symbol] = IERC20Extended(tokenAddress);
        emit TokenAddressSet(symbol, tokenAddress);
    }

    function setExchangeRate(string memory from, string memory to, uint256 rate) external onlyOwner {
        require(address(tokens[from]) != address(0), "From token not set");
        require(address(tokens[to]) != address(0), "To token not set");
        require(rate > 0, "Rate must be > 0");

        bytes32 directKey = keccak256(abi.encodePacked(from, to));
        bytes32 reverseKey = keccak256(abi.encodePacked(to, from));

        exchangeRates[directKey] = rate;

        uint256 reverseRate = (1 ether * 1 ether) / rate;
        exchangeRates[reverseKey] = reverseRate;

        emit ExchangeRateSet(from, to, rate);
    }

    function swap(string memory from, string memory to, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(keccak256(bytes(from)) != keccak256(bytes(to)), "Cannot swap same token");

        IERC20Extended fromToken = tokens[from];
        IERC20Extended toToken = tokens[to];

        require(address(fromToken) != address(0), "From token not initialized");
        require(address(toToken) != address(0), "To token not initialized");

        uint8 fromDecimals = fromToken.decimals();
        uint8 toDecimals = toToken.decimals();

        bytes32 key = keccak256(abi.encodePacked(from, to));
        uint256 rate = exchangeRates[key];
        require(rate > 0, "Rate not set");

        uint256 normalizedAmount = fromDecimals < 18
            ? amount * (10 ** (18 - fromDecimals))
            : amount / (10 ** (fromDecimals - 18));

        uint256 normalizedToAmount = (normalizedAmount * rate) / 1 ether;

        uint256 toAmount = toDecimals < 18
            ? normalizedToAmount / (10 ** (18 - toDecimals))
            : normalizedToAmount * (10 ** (toDecimals - 18));

        require(toToken.balanceOf(address(this)) >= toAmount, "Not enough liquidity");

        require(fromToken.transferFrom(msg.sender, address(this), amount), "TransferFrom failed");
        require(toToken.transfer(msg.sender, toAmount), "Transfer failed");

        emit TokenSwapped(msg.sender, from, to, amount, toAmount);
    }

    function getExpectedOutput(string memory from, string memory to, uint256 amount) public view returns (uint256) {
        IERC20Extended fromToken = tokens[from];
        IERC20Extended toToken = tokens[to];

        require(address(fromToken) != address(0), "From token not initialized");
        require(address(toToken) != address(0), "To token not initialized");

        uint8 fromDecimals = fromToken.decimals();
        uint8 toDecimals = toToken.decimals();

        bytes32 key = keccak256(abi.encodePacked(from, to));
        uint256 rate = exchangeRates[key];
        require(rate > 0, "Rate not set");

        uint256 normalizedAmount = fromDecimals < 18
            ? amount * (10 ** (18 - fromDecimals))
            : amount / (10 ** (fromDecimals - 18));

        uint256 normalizedToAmount = (normalizedAmount * rate) / 1 ether;

        uint256 toAmount = toDecimals < 18
            ? normalizedToAmount / (10 ** (18 - toDecimals))
            : normalizedToAmount * (10 ** (toDecimals - 18));

        return toAmount;
    }

    function withdrawToken(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "Withdraw failed");
        emit TokenWithdrawn(tokenAddress, amount);
    }

    function getPairKey(string memory from, string memory to) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, to));
    }

    function getRate(string memory from, string memory to) external view returns (uint256) {
        return exchangeRates[keccak256(abi.encodePacked(from, to))];
    }
}
