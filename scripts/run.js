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
      [100, 200, 50],
      "Mewtwo",
      "https://i.redd.it/ylhsc8d18ag61.jpg",
      10000,
      50
    );
    await gameContract.deployed();
    console.log("Contrato implantado no endereço:", gameContract.address);
    let txn;
    // Só temos três personagens.
    // Uma NFT com personagem no index 2 da nossa array.
    txn = await gameContract.mintCharacterNFT(2);
    await txn.wait();

    txn = await gameContract.attackBoss();
    await txn.wait();

    txn = await gameContract.attackBoss();
    await txn.wait();

    // Pega o valor da URI da NFT
    let returnedTokenUri = await gameContract.tokenURI(1);
    console.log("Token URI:", returnedTokenUri);

    let allPlayers = await gameContract.getAllPlayers();
    console.log("All players:", allPlayers[0].imageURI);
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