// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
 
import "@OpenZeppelin/contracts/utils/math/SafeMath.sol";


contract TestMapping {
    using SafeMath for uint;

    struct Cagnotte {
        string nom;
        uint montant;
        uint interet;
    }
    Cagnotte[] Cagnottes;
    mapping(string=> uint) CagnotteMap;
    
    function AjoutCagnotte (string calldata _nom, uint _montant) public {
        int arrayIndex = int(CagnotteMap[_nom]) - 1;
        if (arrayIndex == -1) {
            Cagnottes.push(Cagnotte(_nom, _montant, 0));
            CagnotteMap[_nom] = Cagnottes.length;
        }
        else {
            Cagnotte storage currentCagnotte = Cagnottes[uint(arrayIndex)];
            currentCagnotte.montant = currentCagnotte.montant + _montant;
            // currentCagnotte.montant.add(_montant); ne fonctionne pas
        }
    }
    
    function GetMontantCagnotte (string calldata _nom) public view returns (uint) {
        int arrayIndex = int(CagnotteMap[_nom]) - 1;
        if (arrayIndex == -1) {
            return 0;
        }
        else {
            return Cagnottes[uint(arrayIndex)].montant;
        }
    }
}