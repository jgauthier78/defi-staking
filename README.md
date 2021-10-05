Pour mettre en pratique ce concept vous allez devoir construire une Dapp qui permet aux utilisateurs de stake (immobiliser) n'importe quel token ERC20 et d'automatiser l'émission de récompenses aux stakers (fournisseurs de liquidité) sous la forme de tokens. 

La récompense en tokens reçues par les utilisateurs est un élément très important de votre Dapp. Elle doit être proportionnelle à la quantité des fonds bloqués sur le smart contract. Pour ce faire, vous avez besoin de la valeur marchande actuelle de l'actif bloqué, que vous pouvez récupérer en utilisant l’oracle de Chainlink.

L'obtention de données de prix à partir de Chainlink vous offre un moyen de comparer la valeur des tokens bloqués sur le smart contract. Vous pouvez facilement convertir la valeur de n'importe quel token ERC20 en sa valeur ETH afin de calculer et déterminer la valeur exacte de la récompense.

Les spécifications fonctionnelles : 

- Stake son token ERC20 
- Unstake ses tokens 
- Créer son propre token de récompense ou utiliser l’ETH ou un autre token ERC20 (Dai par exemple) 
- La quantité de la récompense doit être proportionnelle à la valeur bloquées sur le smart contract 

Les exigences :
Utilisation de l’oracle Chainlink 

Veuillez indiquer le lien de votre répertoire Github correspondant au défi.

Le contrat :
- nom = AlyraStaking
- fonctions publique
  - Stake (address stakingToken, uint256 amount)
    - will check that amount to be staked is lower or equal to balance(msg.sender)
    - will add the stakingToken in a mapping is not already existing
    - the mapping will contain token address as key and the index of an array to store stakes/widthdraw = type (stake or withdraw), amount and date (now = block.timestamp)
    - will transfer the amount from msg.sender to this (the contract) (always last step to avoid reentrancy)
  - Withdraw (address stakingToken, uint256 amount)
    - will check that
     - the stakingToken address exists in the mapping
     - the total amount for this token is higher or equal to withdrawn amount
     - will store widthdrawn info
     - will calculate rewards for this token = for each staked amount = calculate time since it was staked, this will give a number of days that will be divided by 365 and multiplied by rate/100
     - will transfer
  - GetRewardsBalance ()
     - will calculate rewards for each token in mapping = for each staked amount = calculate time since it was staked, this will give a number of days that will be divided by 365 and multiplied by rate/100
  - WithdrawRewards (uint256 amount)
  
- tests sur Ganache/Remix
  - création de tokens Alyra Test 1 (AT1, 0xA081bae871c250845963b1CfE67f30dEb95E8Cda) et 2 (AT2, 0xDDd408582c9e57FE4d03CF4263dB809F3A0F4a2c) sur address 0 (0xE160994aa9Fb1531D5F25ac40aa53C05F20e6dcC)
  - création du contrat de staking sur address 3 (0xDDd3D3c39fCE44C3e25968B49Fa18ecEb7BDd52D) via truffle deploy --reset
  - adresse du contrat créé = _contractAddress (0xfCF3dd1856F2506503a2Ebe9A95F7503FB2a684F)
  - sous Remix
    - load du script ERC20TokenAT1.sol
    - choix du contrat ERC20TokenAT1 (au dessus de DEPLOY) puis run AtAddress avec l'adresse du token AT1
    - depuis le compte index 1  de Ganache (aka Account 8 (Ganache) sous Metamask) - adresse 0xF02601902610AD104B69A91CE4a8d349E6828608
    - run approve(_contractAddress, 1000000000) pour autoriser le contrat AlyraStaking à transférer (TransferFrom) au nom du compte "Account 8 (Ganache)" (0xF026...)
    - toujours depuis le compte 0xF026, choix du contrat AlyraStaking (au dessus de DEPLOY) puis run AtAddress avec l'adresse du contrat = _contractAddress
    - dans deployed contracts, ouverture de AlyraStaking puis
    - run fonction stake avec _tokenAddress = AT1 et amount = 1000000000
  
Unit Tests à prévoir dans l'ordre :
- pas possible de stake si pas d'allowance
- pas possible de withdrawn si pas de stake fait pour le token donné
- si allowance, pas possible de stake plus que l'allowance
- si allowance, possibilité de stake à niveai de l'allowance