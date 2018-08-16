/**
 * @file DNoteProxy.sol
 * @author sufay
 */


pragma solidity ^0.4.23;


/**
 * @title DNoteDelegator is intended to be an entrance to the underlying contract
 */
contract DNoteDelegator {
    address public DNote; // the underlying contract address
    address public owner; // owner
    
    /**
     * @dev assert caller has access to a function of the modifier
     */
    modifier hasPermission() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev check if the given address is valid
     */
    modifier valid(address addr) {
        if (addr == address(0)) {
            return;
        }

        _;
    }

    /**
     * @dev constructor
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev forward call to DNote
     */
    function() public {
        assembly {
            let dataOffset := mload(0x40) // allocate free memory for input data
            let dataLen := calldatasize // get the data length
            calldatacopy(dataOffset, 0, dataLen) // copy data to allocated memory above
            mstore(0x40, add(dataOffset, dataLen)) // update free memory pointer

            // call
            let success := call(sub(gas, 10000), sload(DNote_slot), callvalue, dataOffset, dataLen, 0, 0)
            
            // handle result
            switch success
            case 1 {
                // call succeeded and return result data
                
                let resultLen := returndatasize // get result data length
                let resultOffset := mload(0x40) // allocate free memory for result data
                returndatacopy(resultOffset, 0, resultLen) // copy result data to memory

                return(resultOffset, resultLen) // return result data
            }
            case 0 {
                // call failed and revert
                revert(0, 0)
            }
        }
    }

    /**
     * @dev set the DNote address
     * @param dnote the destination address
     */
    function setDNote(address dnote) public valid(dnote) hasPermission {
        DNote = dnote;
    }
}
