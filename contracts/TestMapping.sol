// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
 
contract TestMapping {
    uint[] Cagnottes;
    mapping(string=> uint) CagnotteMap;
    
    function AjoutCagnotte (string calldata _nom, uint _montant) public {
        int arrayIndex = int(CagnotteMap[_nom]) - 1;
        if (arrayIndex == -1) {
            Cagnottes.push(_montant);
            CagnotteMap[_nom] = Cagnottes.length;
        }
        else {
            Cagnottes[uint(arrayIndex)] = Cagnottes[uint(arrayIndex)] + _montant;
        }
    }
    
    function GetMontantCagnotte (string calldata _nom) public view returns (uint) {
        int arrayIndex = int(CagnotteMap[_nom]) - 1;
        if (arrayIndex > 0) {
            return Cagnottes[uint(arrayIndex)];
        }
        else {
            return 0;
        }
    }
}
