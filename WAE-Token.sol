// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/extensions/ERC20Burnable.sol";

/// @custom:security-contact info@aeternity.org
contract WrappedAeternity is ERC20, ERC20Burnable {
    constructor(address _admin1, address _admin2, address _admin3) ERC20("Wrapped Aeternity", "WAE") {

        
        // make sure the addresses are unique
        require(_admin1 != _admin2);
        require(_admin2 != _admin3);
        require(_admin1 != _admin3);

        require(_admin1 != address(0x0));
        require(_admin2 != address(0x0));
        require(_admin3 != address(0x0));
        
                //set admins
        admin1 = _admin1;
        admin2 = _admin2;
        admin3 = _admin3;

        // set bogus initial signatures, so multisig works properly;
        cleanupSignatures();
    }

    event wrapped(uint256, address);
    mapping(address => bytes32) public multiSigHashes;

    address public admin1;
    address public admin2;
    address public admin3;

    modifier multiSigRequired(uint256 amount) {
        // check amount
        require (amount > 0, "token amount is zero");

        // check if transaction sender is admin.
        require (msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3);
        // if yes, store his msg.data. 
        multiSigHashes[msg.sender] = keccak256(msg.data);
        // check if all three stored msg.data hash equals to the one of the other admins
        if (
            (multiSigHashes[admin1] == multiSigHashes[admin2]) 
            ||
            (multiSigHashes[admin2] == multiSigHashes[admin3])
            ||
            (multiSigHashes[admin1] == multiSigHashes[admin3])
           ) {
            // if yes, all three admins agreed - continue.
            _;

            // Reset hashes after successful execution
            cleanupSignatures();
        } else {
            // if not (yet), return.
            return;
        }
    }

    function mint(address _to, uint256 _amount) public multiSigRequired(_amount) {
        _mint(_to, _amount);
        emit wrapped(_amount, _to);
    }

    //deleteme
    function cleanupSignatures() private {
        multiSigHashes[admin1] = keccak256("foo");
        multiSigHashes[admin2] = keccak256("bar");
        multiSigHashes[admin3] = keccak256("baz");
    }

    // explicitly convert address to bytes for the hashing function. 
    // see https://ethereum.stackexchange.com/questions/884/how-to-convert-an-address-to-bytes-in-solidity
    function toBytes(address a) public pure returns (bytes memory b){
    assembly {
        let m := mload(0x40)
        a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
        mstore(0x40, add(m, 52))
        b := m
   }
}

}

