// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract MyEpicGame {
  // Nos vamos segurar os atributos dos nossos personagens em uma
  //struct. Sinta-se livre para adicionar o que quiser como um
  //atributo! (ex: defesa, chance de critico, etc).
  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint attackDamage;
  }
  // Uma pequena array vai nos ajudar a segurar os dados padrao dos
  // nossos personagens. Isso vai ajudar muito quando mintarmos nossos
  // personagens novos e precisarmos saber o HP, dano de ataque e etc.
  CharacterAttributes[] defaultCharacters;

  // Dados passados no contrato quando ele for criado inicialmente,
  // inicializando os personagens.
  // Vamos passar esse valores do run.js
  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    uint[] memory characterHp,
    uint[] memory characterAttackDmg
  )
  {
    // Faz um loop por todos os personagens e salva os valores deles no
    // contrato para que possamos usa-los depois para mintar as NFTs
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name: characterNames[i],
        imageURI: characterImageURIs[i],
        hp: characterHp[i],
        maxHp: characterHp[i],
        attackDamage: characterAttackDmg[i]
      }));

      CharacterAttributes memory c = defaultCharacters[i];
      console.log("Personagem inicializado: %s com %s de HP, img %s", c.name, c.hp, c.imageURI);
    }
  }
}