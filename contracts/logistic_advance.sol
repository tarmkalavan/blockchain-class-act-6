// SPDX-License-Identifier: Non-License
pragma solidity 0.8.17;

import "./interfaces/IFishMarket.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

enum StateType {
    Idle,
    Created,
    InTransit,
    Complete,
    Cancel,
    Done
}

struct Deal {
    bytes32 dealId;
    address transporter;
    address customer;
    string productName;
    uint256 minTemperature;
    uint256 maxTemperature;
    uint256 price;
    bool cancelable;
    StateType transportState;
}

contract Logistic is Ownable {
    mapping(bytes32 => Deal) public deals;
    IFishMarket internal fishMarket;

    modifier onlyTransporter(bytes32 dealId) {
        require(msg.sender == deals[dealId].transporter, "unauthorized");
        _;
    }

    modifier onlyCustomer(bytes32 dealId) {
        require(msg.sender == deals[dealId].customer, "unauthorized");
        _;
    }

    constructor(address _fishMarket) {
        fishMarket = IFishMarket(_fishMarket);
    }

    /*
        Function to initalize a initDeal
        @param : customer's address, price (in Ether), productName, quantity
    */
    function initDeal(
        address _customer,
        string memory _productName,
        uint256 _quantity
    ) public onlyOwner returns (Deal memory) {
        Stock memory stock = fishMarket.getStock(_productName);
        // console.log(stock.productName);
        // console.log(stock.price);
        // console.log(stock.minTemperature);
        // console.log(stock.maxTemperature);
        // console.log(stock.quantity);
        require(_quantity <= stock.quantity, "out of order");

        fishMarket.removeStockQuantity(_quantity, _productName);

        bytes32 dealId = keccak256(
            abi.encodePacked(_customer, block.timestamp)
        );

        Deal storage deal = deals[dealId];

        deal.dealId = dealId;
        deal.customer = _customer;
        deal.minTemperature = stock.minTemperature;
        deal.maxTemperature = stock.maxTemperature;
        deal.price = _quantity * stock.price;
        deal.productName = _productName;
        deal.transportState = StateType.Created;

        return deal;
    }

    /*
        Function to transport to customer
        @param : transporter's address
    */
    function transport(bytes32 dealId, address _transporter) public onlyOwner {
        Deal storage deal = deals[dealId];

        require(
            deal.transportState == StateType.Created,
            "invalid transportState"
        );

        deal.transporter = _transporter;
        deal.transportState = StateType.InTransit;
    }

    /*
        Function to update sensor from transporter
        @param : current temp
    */
    function updateTemp(bytes32 dealId, uint256 _temp)
        public
        onlyTransporter(dealId)
    {
        Deal storage deal = deals[dealId];

        require(
            deal.transportState == StateType.InTransit,
            "invalid transportState"
        );

        if (_temp > deal.maxTemperature || _temp < deal.minTemperature) {
            deal.cancelable = true;
        }
    }

    /*
        Function to cancel current deal if measured temperature is out of range
        @param: -
    */
    function cancelDeal(bytes32 dealId) public onlyCustomer(dealId) {
        Deal storage deal = deals[dealId];

        require(
            deal.transportState == StateType.InTransit,
            "invalid transportState"
        );
        require(deal.cancelable == true, "unmatched cancel condition");

        deal.transportState = StateType.Cancel;
    }

    /*
        Function to complete and pay for deal
        @param : -
        This function require ether to be transfered.
    */
    function pay(bytes32 dealId) public payable onlyCustomer(dealId) {
        Deal storage deal = deals[dealId];

        require(
            deal.transportState == StateType.InTransit,
            "invalid transportState"
        );
        require(msg.value == deal.price, "invalid amount");

        deal.transportState = StateType.Complete;
    }

    /*
        Function for owner to get ether from contract 
        @param : -
    */
    function clearance(bytes32 dealId) public payable onlyOwner {
        Deal storage deal = deals[dealId];

        require(
            deal.transportState == StateType.Complete ||
                deal.transportState == StateType.Cancel,
            "invalid transportState"
        );

        if (deal.transportState == StateType.Complete) {
            uint256 amountToOwner = (deal.price * 9) / 10;
            _transfer(owner(), amountToOwner);
            _transfer(deal.transporter, deal.price - amountToOwner);
        }

        deal.transportState = StateType.Done;
    }

    function _transfer(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));
        if (!success) {
            revert("transfer ETH error");
        }
    }

    receive() external payable {
        revert("Not support sending Ethers to this contract directly.");
    }
}
