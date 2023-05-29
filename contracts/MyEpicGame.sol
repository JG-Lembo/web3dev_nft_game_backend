// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./libraries/Base64.sol";

import "hardhat/console.sol";

contract MyEpicGame is ERC721 {

  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;
    string mainColor;
    uint hp;
    uint maxHp;
    uint attackDamage;
    uint lastDefeatedAt;
    uint lastSpecialAbilityUse;
  }

  struct PlayerCharacters {
    address holderAddress;
    uint256 tokenId;
    string imageURI;
    uint256 damageDealt;
  }

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  CharacterAttributes[] defaultCharacters;

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
    bool isBurnt;
    uint256 lastBurntAt;
    bool isFrozen;
    uint256 lastFrozenAt;
  }

  BigBoss public bigBoss; 

  bool playersProtected;
  uint256 playersLastProtectedAt;

  event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
  event AttackComplete(uint newBossHp, uint newPlayerHp, uint damageDealt);
  event SpecialAttackComplete(uint newBossHp, uint damageDealt);

  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    string[] memory characterMainColor,
    uint[] memory characterHp,
    uint[] memory characterAttackDmg,
    string memory bossName,
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
      mainColor: bossMainColor,
      isBurnt: false,
      lastBurntAt: 0,
      isFrozen: false,
      lastFrozenAt: 0
    });

    playersProtected = false;
    playersLastProtectedAt = 0;

    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name: characterNames[i],
        imageURI: characterImageURIs[i],
        mainColor: characterMainColor[i],
        hp: characterHp[i],
        maxHp: characterHp[i],
        attackDamage: characterAttackDmg[i],
        lastDefeatedAt: 0,
        lastSpecialAbilityUse: 0
      }));
    }

    _tokenIds.increment();
  }

  function mintCharacterNFT(uint _characterIndex) external {
    uint256 newItemId = _tokenIds.current();

    _safeMint(msg.sender, newItemId);

    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      mainColor: defaultCharacters[_characterIndex].mainColor,
      hp: defaultCharacters[_characterIndex].hp,
      maxHp: defaultCharacters[_characterIndex].maxHp,
      attackDamage: defaultCharacters[_characterIndex].attackDamage,
      lastDefeatedAt: defaultCharacters[_characterIndex].lastDefeatedAt,
      lastSpecialAbilityUse: defaultCharacters[_characterIndex].lastSpecialAbilityUse
    });

    nftHolders[msg.sender] = newItemId;
    holderAddresses.push(msg.sender);

    _tokenIds.increment();

    emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

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
            '", "attributes": [ { "trait_type": "Health Points", "value": ', Strings.toString(charAttributes.hp),', "max_value":', Strings.toString(charAttributes.maxHp),'}, { "trait_type": "Attack Damage", "value": ',
            Strings.toString(charAttributes.attackDamage),'} ]}'
          )
        )
      )
    );

    string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
    );

    return output;
  }

  function applyDamageConditions(uint256 damage) public view returns (uint256) {
    if (bigBoss.isBurnt) damage *= 2;
    if (bigBoss.isFrozen) damage /= 2;
    return damage;
  }

  function attackBoss() public {
    uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
    CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];

    updateConditions();

    require (
        player.hp > 0 && bigBoss.hp > 0,
        "Erro: Personagem e/ou o boss devem ter HP para atacar o boss."
    );

    uint256 critChance = uint256(keccak256(abi.encodePacked(player.hp, msg.sender, bigBoss.hp, block.timestamp))) % 100;
    uint256 attackDamage = player.attackDamage;
    if (critChance < 10) attackDamage *= 2;
    attackDamage = applyDamageConditions(attackDamage);

    dealBossDamage(attackDamage, msg.sender);

    uint bossDamage = bigBoss.attackDamage;
    if (playersProtected) bossDamage /= 2;
    uint256 hitChance = uint256(keccak256(abi.encodePacked(msg.sender, player.hp, block.timestamp))) % 100;
    if (bigBoss.isFrozen && hitChance >= 10) bossDamage=0;

    if (player.hp <= bossDamage) {
        player.hp = 0;
        player.lastDefeatedAt = block.timestamp;
    } else {
        player.hp = player.hp - bossDamage;
    }

    emit AttackComplete(bigBoss.hp, player.hp, attackDamage);
  }

  function dealBossDamage(uint256 damage, address attacker) private {
    if (bigBoss.hp < damage) {
        damageDealt[attacker] = damageDealt[attacker] + bigBoss.hp;
        bigBoss.hp = 0;
    } else {
        bigBoss.hp = bigBoss.hp - damage;
        damageDealt[attacker] = damageDealt[attacker] + damage;
    }
  }

  function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
    uint256 userNftTokenId = nftHolders[msg.sender];
    if (userNftTokenId > 0) {
        return nftHolderAttributes[userNftTokenId];
    }
    else {
        CharacterAttributes memory emptyStruct;
        return emptyStruct;
    }
  }

  function getTimeSinceDefeat() public view returns (uint256) {
    return block.timestamp - nftHolderAttributes[nftHolders[msg.sender]].lastDefeatedAt;
  }

  function healCharacter() public {
    uint256 playerTokenId = nftHolders[msg.sender];
    CharacterAttributes storage playerCharacter = nftHolderAttributes[playerTokenId];

    require(playerCharacter.hp == 0,
      "O personagem deve estar sem vida para ser curado");

    uint256 timePassed= getTimeSinceDefeat();
    if (timePassed < 28800) {
      revert("Nao se passaram as 8 horas necessarias");
    }

    playerCharacter.hp = playerCharacter.maxHp;
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

  function getTimeSinceSpecialAbilityUse() public view returns (uint) {
    return block.timestamp - nftHolderAttributes[nftHolders[msg.sender]].lastSpecialAbilityUse;
  }

  function useSpecialAbility() public {

    uint256 playerTokenId = nftHolders[msg.sender];
    CharacterAttributes storage character = nftHolderAttributes[playerTokenId];

    require (getTimeSinceSpecialAbilityUse() >= 3600,
      "Voce ainda nao pode usar sua habilidade especial novamente");

    updateConditions();

    uint256 attackDamage;

    if (keccak256(abi.encodePacked(character.name)) == keccak256(abi.encodePacked("Charizard"))) {
      attackDamage = defaultCharacters[0].attackDamage;
      attackDamage = applyDamageConditions(attackDamage);
      dealBossDamage(attackDamage, msg.sender);
      
      bigBoss.isBurnt = true;
      bigBoss.lastBurntAt = block.timestamp;
      emit SpecialAttackComplete(bigBoss.hp, attackDamage);
    }
    if (keccak256(abi.encodePacked(character.name)) == keccak256(abi.encodePacked("Blastoise"))) {
      attackDamage = defaultCharacters[1].attackDamage;
      attackDamage = applyDamageConditions(attackDamage);
      dealBossDamage(attackDamage, msg.sender);
      
      bigBoss.isFrozen = true;
      bigBoss.lastFrozenAt = block.timestamp;    
      emit SpecialAttackComplete(bigBoss.hp, attackDamage);
    }
    if (keccak256(abi.encodePacked(character.name)) == keccak256(abi.encodePacked("Venusaur"))) {
      playersProtected = true;
      playersLastProtectedAt = block.timestamp;
    }

    character.lastSpecialAbilityUse = block.timestamp;
  }

  function isBossBurnt() public view returns(bool) {
    if (block.timestamp - bigBoss.lastBurntAt >= 3600) {
      return false;
    }
    return bigBoss.isBurnt;
  }

  function isBossFrozen() public view returns(bool) {
    if (block.timestamp - bigBoss.lastFrozenAt >= 300) {
      return false;
    }
    return bigBoss.isFrozen;
  }

  function arePlayersProtected() public view returns (bool) {
    if (block.timestamp - playersLastProtectedAt >= 3600) {
      return false;
    }
    return playersProtected;
  }

  function updateConditions() private {
    if (isBossBurnt()) {
      if (block.timestamp - bigBoss.lastBurntAt >= 3600) bigBoss.isBurnt = false;
    }
    if (isBossFrozen()) {
      if (block.timestamp - bigBoss.lastFrozenAt >= 300) bigBoss.isFrozen = false;
    }
    if (arePlayersProtected()) {
      if (block.timestamp - playersLastProtectedAt >= 3600) playersProtected = false;
    }
  }


}