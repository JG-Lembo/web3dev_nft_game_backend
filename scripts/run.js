const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
    const gameContract = await gameContractFactory.deploy(
      ["Charizard", "Blastoise", "Venusaur"],
          [
              "https://i.pinimg.com/originals/bb/06/15/bb06152d6edb8c578216fcdebd21715b.jpg",
              "https://i.pinimg.com/originals/4e/fb/a2/4efba28478e043be9815d1b2caa5b3bc.jpg",
              "https://i.pinimg.com/originals/08/ea/0a/08ea0ad8365170b5f3d3d0245c9eae9d.jpg",
          ],
      [100, 50, 200], // HP values
      [100, 200, 50] // Attack damage values
    );
    await gameContract.deployed();
    console.log("Contrato implantado no endereço:", gameContract.address);
};
  
const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
};
  
runMain();