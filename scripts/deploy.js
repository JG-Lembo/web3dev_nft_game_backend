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