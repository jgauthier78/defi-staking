// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
 
contract TestMapping {
    uint[] Cagnottes;
    mapping(string=> uint) CagnotteMap;
    
    function AjoutCagnotte (string calldata _nom, uint _montant) public {
        uint arrayIndex = CagnotteMap[_nom];
        if (Cagnottes.length == 0 || arrayIndex == 0) {
            Cagnottes.push(_montant);
            CagnotteMap[_nom] = Cagnottes.length;
        }
        else {
            Cagnottes[arrayIndex-1] = Cagnottes[arrayIndex-1] + _montant;
        }
    }
    
    function GetMontantCagnotte (string calldata _nom) public view returns (uint) {
        uint arrayIndex = CagnotteMap[_nom];
        if (arrayIndex > 0) {
            return Cagnottes[arrayIndex-1];
        }
        else {
            return 0;
        }
    }
}
