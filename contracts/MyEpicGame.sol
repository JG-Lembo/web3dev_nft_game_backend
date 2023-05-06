// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Contrato NFT para herdar.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Funcoes de ajuda que o OpenZeppelin providencia.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./libraries/Base64.sol";

import "hardhat/console.sol";

// Nosso contrato herda do ERC721, que eh o contrato padrao de
// NFT!
contract MyEpicGame is ERC721 {

  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;
    string mainColor;
    uint hp;
    uint maxHp;
    uint attackDamage;
  }

  struct PlayerCharacters {
    address holderAddress;
    uint256 tokenId;
    string imageURI;
    uint256 damageDealt;
  }

  // O tokenId eh o identificador unico das NFTs, eh um numero
  // que vai incrementando, como 0, 1, 2, 3, etc.

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  CharacterAttributes[] defaultCharacters;

  // Criamos um mapping do tokenId => atributos das NFTs.
  mapping(uint256 => CharacterAttributes) public nftHolderAttributes;
  mapping(address => uint256) public nftHolders;
  mapping(address => uint256) public damageDealt;
  address[] holderAddresses;

  struct BigBoss {
    string name;
    string imageURI;
    string mainColor;
    uint hp;
    uint maxHp;
    uint attackDamage;
  }

  BigBoss public bigBoss; 

  event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
  event AttackComplete(uint newBossHp, uint newPlayerHp, uint damageDealt);

  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    string[] memory characterMainColor,
    uint[] memory characterHp,
    uint[] memory characterAttackDmg,
    string memory bossName, // Essas novas variáveis serão passadas via run.js ou deploy.js
    string memory bossImageURI,
    string memory bossMainColor,
    uint bossHp,
    uint bossAttackDamage
  )
  ERC721("Heroes", "HERO")
  {

    bigBoss = BigBoss({
      name: bossName,
      imageURI: bossImageURI,
      hp: bossHp,
      maxHp: bossHp,
      attackDamage: bossAttackDamage,
      mainColor: bossMainColor
    });

    console.log("Boss inicializado com sucesso %s com HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name: characterNames[i],
        imageURI: characterImageURIs[i],
        mainColor: characterMainColor[i],
        hp: characterHp[i],
        maxHp: characterHp[i],
        attackDamage: characterAttackDmg[i]
      }));

      CharacterAttributes memory c = defaultCharacters[i];

      // O uso do console.log() do hardhat nos permite 4 parametros em qualquer order dos seguintes tipos: uint, string, bool, address

      console.log("Personagem inicializado: %s com %s de HP, img %s", c.name, c.hp, c.imageURI);
    }

    // Eu incrementei tokenIds aqui para que minha primeira NFT tenha o ID 1.
    // Mais nisso na aula!
    _tokenIds.increment();
  }

  // Usuarios vao poder usar essa funcao e pegar a NFT baseado no personagem que mandarem!
  function mintCharacterNFT(uint _characterIndex) external {
    // Pega o tokenId atual (começa em 1 já que incrementamos no constructor).
    uint256 newItemId = _tokenIds.current();

    // A funcao magica! Atribui o tokenID para o endereço da carteira de quem chamou o contrato.

    _safeMint(msg.sender, newItemId);

    // Nos mapeamos o tokenId => os atributos dos personagens. Mais disso abaixo

    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      mainColor: defaultCharacters[_characterIndex].mainColor,
      hp: defaultCharacters[_characterIndex].hp,
      maxHp: defaultCharacters[_characterIndex].maxHp,
      attackDamage: defaultCharacters[_characterIndex].attackDamage
    });

    console.log("Mintou NFT c/ tokenId %s e characterIndex %s", newItemId, _characterIndex);

    // Mantem um jeito facil de ver quem possui a NFT
    nftHolders[msg.sender] = newItemId;
    holderAddresses.push(msg.sender);

    // Incrementa o tokenId para a proxima pessoa que usar.
    _tokenIds.increment();

    emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

    string memory strHp = Strings.toString(charAttributes.hp);
    string memory strMaxHp = Strings.toString(charAttributes.maxHp);
    string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            charAttributes.name,
            ' -- NFT #: ',
            Strings.toString(_tokenId),
            '", "description": "An epic NFT", "image": "ipfs://',
            charAttributes.imageURI,
            '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
            strAttackDamage,'} ]}'
          )
        )
      )
    );

    string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
    );

    return output;
  }

  function getAttackDamage (CharacterAttributes memory player, address sender) public view returns (uint256) {
    uint256 critChance = uint256(keccak256(abi.encodePacked(player.attackDamage, player.hp, sender, bigBoss.hp, _tokenIds.current())));
    critChance = critChance % 100;
    if (critChance < 10) return player.attackDamage * 2;
    return player.attackDamage;
  }

  function attackBoss() public {
    // Pega o estado da NFT do jogador.
    uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
    CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];

    console.log("\nJogador com personagem %s ira atacar. Tem %s de HP e %s de PA", player.name, player.hp, player.attackDamage);
    console.log("Boss %s tem %s de HP e %s de PA", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);

    // Checa se o hp do jogador é maior que 0.
    require (
        player.hp > 0,
        "Erro: Personagem deve ter HP para atacar o boss."
    );

    // Checa que o hp do boss é maior que 0.
    require (
        bigBoss.hp > 0,
        "Erro: Boss deve ter HP para atacar."
    );

    uint256 attackDamage = getAttackDamage(player, msg.sender);

    // Permite que o jogador ataque o boss.
    if (bigBoss.hp < attackDamage) {
        damageDealt[msg.sender] = damageDealt[msg.sender] + bigBoss.hp;
        bigBoss.hp = 0;
    } else {
        bigBoss.hp = bigBoss.hp - attackDamage;
        damageDealt[msg.sender] = damageDealt[msg.sender] + attackDamage;
    }

    // Permite que o boss ataque o jogador.
    if (player.hp < bigBoss.attackDamage) {
        player.hp = 0;
    } else {
        player.hp = player.hp - bigBoss.attackDamage;
    }

    console.log("Jogador atacou o boss. Boss ficou com HP: %s", bigBoss.hp);
    console.log("Boss atacou o jogador. Jogador ficou com hp: %s\n", player.hp);

    emit AttackComplete(bigBoss.hp, player.hp, attackDamage);
  }

  function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
    // Pega o tokenId do personagem NFT do usuario
    uint256 userNftTokenId = nftHolders[msg.sender];
    // Se o usuario tiver um tokenId no map, retorne seu personagem
    if (userNftTokenId > 0) {
        return nftHolderAttributes[userNftTokenId];
    }
    // Senão, retorne um personagem vazio
    else {
        CharacterAttributes memory emptyStruct;
        return emptyStruct;
    }
  }

  function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
    return defaultCharacters;
  }

  function getBigBoss() public view returns (BigBoss memory) {
    return bigBoss;
  }

  function getAllPlayers() public view returns (PlayerCharacters[] memory) {
    PlayerCharacters[] memory characters =  new PlayerCharacters[](holderAddresses.length);
    for (uint i = 0; i < holderAddresses.length; i++) {
      address holderAddress = holderAddresses[i];
      uint256 holderTokenId = nftHolders[holderAddress];
      characters[i] = PlayerCharacters({
        holderAddress: holderAddress,
        tokenId: holderTokenId,
        imageURI: nftHolderAttributes[holderTokenId].imageURI,
        damageDealt: damageDealt[holderAddress]
      });
    }
    return characters;
  }


}