import "@nomiclabs/hardhat-ethers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { Contract, ContractFactory } from "ethers"
import { ethers } from "hardhat"
describe("Advance Logistic Contract Test -  Initialize Deal", function () {
  let fishMarketFactory: ContractFactory
  let logisticFactory: ContractFactory

  let fishMarketContract: Contract
  let logisticContract: Contract

  let owner: SignerWithAddress
  let customer: SignerWithAddress
  let unrelatedUser: SignerWithAddress

  enum StateType {
    Idle,
    Created,
    InTransit,
    Complete,
    Cancel,
    Done,
  }

  before(async function () {
    ;[owner, customer, unrelatedUser] = await ethers.getSigners()

    fishMarketFactory = await ethers.getContractFactory("FishMarket")
    logisticFactory = await ethers.getContractFactory("Logistic")

    fishMarketContract = await fishMarketFactory.connect(owner).deploy()
    await fishMarketContract.deployed()

    logisticContract = await logisticFactory
      .connect(owner)
      .deploy(fishMarketContract.address)

    await logisticContract.deployed()
  })
  describe("Initialize Deal", function () {
    it("only owner should be able to initialize deals", async function () {
      await expect(
        logisticContract
          .connect(unrelatedUser)
          .initDeal(customer.address, "Product A", 2)
      ).to.be.reverted
    })

    it("product must be existed before making any deals related to particular product", async function () {
      await expect(
        logisticContract
          .connect(owner)
          .initDeal(customer.address, "This product DNS", 2)
      ).to.be.revertedWith("product is not exist.")
    })

    it("stock of the product must be sufficient for the order", async function () {
      await fishMarketContract
        .connect(owner)
        .addNewProduct(ethers.utils.parseEther("1"), 10, 30, "Assignment 6")

      await fishMarketContract
        .connect(owner)
        .addStockQuantity(100, "Assignment 6")

      await expect(
        logisticContract
          .connect(owner)
          .initDeal(customer.address, "Assignment 6", 100000)
      ).to.be.revertedWith("out of order")
    })

    it("the deal must be initalized successfully", async function () {
      // No state changes due to callStatic
      const createdDeal = await logisticContract
        .connect(owner)
        .callStatic.initDeal(customer.address, "Assignment 6", 5)

      expect(createdDeal.customer).to.equal(customer.address)
      expect(createdDeal.minTemperature).to.equal(10)
      expect(createdDeal.maxTemperature).to.equal(30)
      expect(createdDeal.price).to.equal(ethers.utils.parseEther("5"))
      expect(createdDeal.productName).to.equal("Assignment 6")
      expect(createdDeal.transportState).to.equal(StateType.Created)

      // Actual call
      await logisticContract
        .connect(owner)
        .initDeal(customer.address, "Assignment 6", 5)
      const stock = await fishMarketContract
        .connect(owner)
        .getStock("Assignment 6")

      expect(stock.quantity).to.equal(95)
    })
  })
})
