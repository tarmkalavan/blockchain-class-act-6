// SPDX-License-Identifier: Non-License
pragma solidity ^0.8.17;

struct Stock {
    bytes32 productId;
    string productName;
    uint256 price;
    uint256 minTemperature;
    uint256 maxTemperature;
    uint256 quantity;
}

interface IFishMarket {
    function addNewProduct(
        uint256 _price,
        uint256 _minTemperature,
        uint256 _maxTemperature,
        string memory _productName
    ) external returns (bytes32);

    function getStock(string memory _productName)
        external
        view
        returns (Stock memory);

    function addStockQuantity(uint256 _quantity, string memory _productName)
        external;

    function removeStockQuantity(uint256 _quantity, string memory _productName)
        external;

    function updateStockPrice(uint256 _price, string memory _productName)
        external;

    function updateStockTemperature(
        uint256 _minTemperature,
        uint256 _maxTemperature,
        string memory _productName
    ) external;
}
