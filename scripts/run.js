const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
    const gameContract = await gameContractFactory.deploy(
      ["Charizard", "Blastoise", "Venusaur"],
      [
          "QmVfBczCkr4wzb6qivHNHHVFDZR3ZhZnuotR8o4wrJtHFc",
          "QmdTGXhM7tfPoLzu7YkDTKHaGKh4DxeareA4tYGJmbjA4s",
          "QmQRGnJNfNV5t3JcutQiYiHqnvRJfPBpmeHEicmN6qGzYV",
      ],
      ["#e4833e", "#1f88c2", "#1ad6d7"],
      [100, 50, 200], // HP values
      [100, 200, 50],
      "Mewtwo",
      "QmeKNQS2rcRwa9FiF7F9Go5CqhVfENUfGk6G7Cabpdr9cd",
      "#d86c8c",
      10000,
      50
    );
    await gameContract.deployed();
    console.log("Contrato implantado no endereço:", gameContract.address);

    // Só temos três personagens.
    // Uma NFT com personagem no index 2 da nossa array.
    txn = await gameContract.mintCharacterNFT(0);
    await txn.wait();

    txn = await gameContract.attackBoss();
    await txn.wait();

    txn = await gameContract.attackBoss();
    await txn.wait();

    let timePassed = await gameContract.getTimeSinceDefeat();
    console.log(timePassed);

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