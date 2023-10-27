const hre = require("hardhat");

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
async function main() {
  //Deploy NFT contract
  const nftContract = await hre.ethers.deployContract("CryptoDevsNFT");
  await nftContract.waitForDeployment();
  console.log("CryptoDevs deployed to: ", nftContract.target);
  //Deploy the Fake Marketplace Contract
  const fakeNftMarketplaceContract = await hre.ethers.deployContract("FakeNFTMarketplace")
  await fakeNftMarketplaceContract.waitForDeployment();
  console.log("Fake NFT Markertplace has been deployed to: ", fakeNftMarketplaceContract.target);
  //Deploy the DAO contract
  const amount = await hre.ethers.parseEther("1");
  const daoContract = await hre.ethers.deployContract("CryptoDevsDAO", [
    fakeNftMarketplaceContract.target,
    nftContract.target,
  ], { value: amount, });
  await daoContract.waitForDeployment();
  console.log("CryptoDevsDAO deployed to:", daoContract.target);
  //@dev sleep for 30 seconds to let ethereum catch up with the deployments
  await sleep(30 * 1000);
  //@dev verify the NFT contract
  await hre.run("verify:verify", {
    address: nftContract.target,
    constructorArguments: [],
  });
  //@dev verify the Fake NFT Marketplace
  await hre.run("verify:verify", {
    address: fakeNftMarketplaceContract.target,
    constructorArguments: [],
  });
  //@dev verify the DAO contract
  await hre.run("verify:verify", {
    address: daoContract.target,
    constructorArguments: [
      fakeNftMarketplaceContract.target,
      nftContract.target,
    ],
  });
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
