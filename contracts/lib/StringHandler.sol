/**
 * @file StringHandler.sol
 * @author sufay
 */

pragma solidity ^0.4.23;


/**
 * @title a library for handling string
 */
library StringHandler {
    /**
     * @dev test if the given strings are equal
     * @param _first the first string
     * @param _second the second string
     */
    function equal(string _first, string _second) public pure returns (bool) {
        return (keccak256(bytes(_first)) == keccak256(bytes(_second)));
    }

     /**
     * @dev check if the specified string is empty
     * @param _str the specified string
     */
    function empty(string _str) public pure returns (bool) {
        return (bytes(_str).length == 0);
    }
}
