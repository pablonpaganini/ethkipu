const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Auction", function () {
  let owner, bidder1, bidder2;
  let auction;

  before(async () => {
    [owner, bidder1, bidder2] = await ethers.getSigners();
    const Auction = await ethers.getContractFactory("Auction", owner);
    auction = await Auction.deploy();
    await auction.deployed();
  });

  it("no debería permitir abrir la subasta a quien no es owner", async () => {
    await expect(
      auction.connect(bidder1).openAuction(ethers.utils.parseEther("1"), 60)
    ).to.be.revertedWith("Caller is not owner");
  });
  it("no debería poder pujar en la subasta no abierta", async () => {
    await expect(
      auction.connect(bidder1).bid({ value: ethers.utils.parseUnits("1.1", "gwei") })
    ).to.be.revertedWith("Auction is not open yet");
  });
  it("debería permitir abrir la subasta a quien es owner", async () => {
    await expect(
      auction.connect(owner).openAuction(ethers.utils.parseUnits("1", "gwei"), 30)
    ).to.not.be.reverted;
  });
  it("no debería poder abrir una subasta ya abierta", async () => {
    await expect(
      auction.connect(owner).openAuction(ethers.utils.parseUnits("1", "gwei"), 60)
    ).to.be.revertedWith("Auction is already opened");
  });
  it("debería permitir pujar correctamente y emitir evento", async () => {
    await expect(
      auction.connect(bidder1).bid({ value: ethers.utils.parseUnits("1.1", "gwei") })
    )
      .to.emit(auction, "EventNewBid")
      .withArgs(bidder1.address, ethers.utils.parseUnits("1.1", "gwei"));

    const winner = await auction.winner();
    expect(winner[0]).to.equal(bidder1.address);
  });
  it("debería rechazar puja menor al mínimo", async () => {
    await expect(
      auction.connect(bidder2).bid({ value: ethers.utils.parseUnits("0.5", "gwei") })
    ).to.be.revertedWith("Bid must be greater or equal to the minimum amount.");
  });
  it("debería rechazar puja si no supera el mínimo con 5% extra", async () => {
    await expect(
      auction.connect(bidder2).bid({ value: ethers.utils.parseUnits("1.11", "gwei") })
    ).to.be.revertedWith("Bid must be greater to the best bid plus 5%.");
  });
  it("debería permitir pujar correctamente superando al ganador y emitir evento", async () => {
    await expect(
      auction.connect(bidder2).bid({ value: ethers.utils.parseUnits("1.2", "gwei") })
    )
      .to.emit(auction, "EventNewBid")
      .withArgs(bidder2.address, ethers.utils.parseUnits("1.2", "gwei"));

    const winner = await auction.winner();
    expect(winner[0]).to.equal(bidder2.address);
  });
  it("debería permitir pujar correctamente superando al ganador y emitir evento otra vez", async () => {
    await expect(
      auction.connect(bidder1).bid({ value: ethers.utils.parseUnits("1.3", "gwei") })
    )
      .to.emit(auction, "EventNewBid")
      .withArgs(bidder1.address, ethers.utils.parseUnits("1.3", "gwei") );

    const winner = await auction.winner();
    expect(winner[0]).to.equal(bidder1.address);
  });
  it("debería permitir reclamar saldo excedente", async () => {
    await expect(auction.connect(bidder1).claims()).to.not.be.reverted;
  });
  it("debería fallar si no hay saldo para reclamar", async () => {
    await expect(auction.connect(bidder1).claims()).to.be.revertedWith("Nothing to claim");
  });
  it("no debería permitir reabrir una subasta cerrada", async () => {
    await expect(
      auction.connect(owner).closeAuction()
    ).to.emit(auction, "EventAuctionClosed");
    await expect(
      auction.connect(owner).openAuction(ethers.utils.parseUnits("1", "gwei"), 30)
    ).to.be.reverted;
  })
  it("no debería emitir EventAuctionClosed si se puja con subasta previamente cerrada", async () => {
    await expect(
      auction.connect(bidder1).bid({ value: ethers.utils.parseEther("1.5") })
    ).to.not.emit(auction, "EventAuctionClosed");
  });
  it("debería reembolsar postores no ganadores cuando termina", async function () {
    await new Promise(resolve => setTimeout(resolve, 5000));
    await expect(auction.connect(owner).refund(bidder2.address)).to.not.be.reverted;
    await new Promise(resolve => setTimeout(resolve, 3000));
    const balance = await auction.connect(bidder2).getBidderBalance();
    expect(balance).to.equal(0);
  });
  it("no debería reembolsar postores no ganadores nuevamente", async function () {
    await expect(auction.connect(owner).refund(bidder2.address)).to.be.reverted;
  });
  it("debería permitir withdraw al owner", async () => {
    const balance = await ethers.provider.getBalance(owner.address);
    
    await expect(auction.connect(owner).withdraw()).to.not.be.reverted;
    let b = await ethers.provider.getBalance(owner.address);
    await expect(b).to.be.above(balance);
    b = await ethers.provider.getBalance(auction.address);
    await expect(b).to.equal(ethers.constants.Zero);
  });

});
