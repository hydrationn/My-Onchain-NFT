// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
   __  __      __    _ __
  / / / /___  / /_  (_) /_
 / / / / __ \/ __ \/ / __/
/ /_/ / /_/ / /_/ / / /_
\____/ .___/_.___/_/\__/
    /_/
    ____                  __
   / __ \____ _____  ____/ /___  ____ ___
  / /_/ / __ `/ __ \/ __  / __ \/ __ `__ \
 / _, _/ /_/ / / / / /_/ / /_/ / / / / / /
/_/ |_|\__,_/_/ /_/\__,_/\____/_/ /_/ /_/

   ______                           __
  / ____/__  ____  ___  _________ _/ /_____  _____
 / / __/ _ \/ __ \/ _ \/ ___/ __ `/ __/ __ \/ ___/
/ /_/ /  __/ / / /  __/ /  / /_/ / /_/ /_/ / /
\____/\___/_/ /_/\___/_/   \__,_/\__/\____/_/

*/

/**
 * @title UpbitRandomGenerator
 * @dev Generate approximated random numbers by blockhash
 */
contract UpbitRandomGenerator {
    /*
     * @dev Mapping of block number to block hash
     * @notice This is used to store block hashes for generating random numbers
     *        as blockhash can only be used for the most recent 256 blocks
     */
    mapping(uint256 => bytes32) public cachedBlockHashes;

    event RandomNumbers(
        uint256 indexed max, uint256 indexed count, uint256 indexed blockNumber, string salt, uint256[] randomNumbers
    );

    error AlreadyCachedBlockHash();
    error InvalidCount();
    error InvalidBlockNumber();

    receive() external payable {
        // solhint-disable-next-line reason-string
        revert();
    }

    /**
     * @notice Record random numbers
     * @param max Maximum number to generate random numbers for
     * @param count Number of random numbers to generate
     * @param blockNumber Block number to use for generating random numbers
     * @param salt Salt to use for generating random numbers
     * @dev This function generates random numbers and emits an event with the generated random numbers
     */
    function recordRandomNumbers(uint256 max, uint256 count, uint256 blockNumber, string calldata salt) external {
        if (cachedBlockHashes[blockNumber] == bytes32(0)) {
            cacheBlockhash(blockNumber);
        }

        emit RandomNumbers(max, count, blockNumber, salt, getRandomNumbers(max, count, blockNumber, salt));
    }

    /**
     * @notice Check if my number is a winner
     * @param max Maximum number to generate random numbers for
     * @param count Number of random numbers to generate
     * @param blockNumber Block number to use for generating random numbers
     * @param salt Salt to use for generating random numbers
     * @param myNumber My number to check if it is a winner
     * @return bool True if the winning number is in the random numbers
     */
    function checkIfImWinner(uint256 max, uint256 count, uint256 blockNumber, string calldata salt, uint256 myNumber)
        external
        view
        returns (bool)
    {
        uint256[] memory randomNumbers = getRandomNumbers(max, count, blockNumber, salt);
        for (uint256 i = 0; i < count; i++) {
            if (randomNumbers[i] == myNumber) return true;
        }
        return false;
    }

    /**
     * @notice Store block hash for generating random numbers
     * @param blockNumber Block number to store block hash for
     * @dev This function stores block hash for generating random numbers. This function was designed
     * to be called internally, but it can also be called externally if necessary, such as when it needs
     * to be invoked in advance and recordRandomNumbers is to be executed later.
     */
    function cacheBlockhash(uint256 blockNumber) public {
        if (blockhash(blockNumber) == bytes32(0)) revert InvalidBlockNumber();
        if (cachedBlockHashes[blockNumber] != bytes32(0)) {
            revert AlreadyCachedBlockHash();
        }
        cachedBlockHashes[blockNumber] = blockhash(blockNumber);
    }

    /**
     * @notice Generate random numbers
     * @param max Maximum number to generate random numbers for
     * @param count Number of random numbers to generate
     * @param blockNumber Block number to use for generating random numbers
     * @param salt Salt to use for generating random numbers
     * @return randomNumbers Array of random numbers
     * @dev This function generates random numbers using block hash and salt. It uses bitwise operations for
     * memory efficiency.
     */
    function getRandomNumbers(uint256 max, uint256 count, uint256 blockNumber, string memory salt)
        public
        view
        returns (uint256[] memory)
    {
        if (count == 0 || max < count) revert InvalidCount();

        bytes32 blockHash = blockhash(blockNumber);
        if (blockHash == bytes32(0)) revert InvalidBlockNumber();

        uint256 maxNumber = max + 1;
        uint256 nonce = 0;
        bytes32 saltBytes = keccak256(abi.encodePacked(salt));

        uint256[] memory randomNumbers = new uint256[](count);
        /**
         * @dev Local array to store drawn numbers, optimized for memory efficiency.
         * Each uint256 is treated as like an array of 256 boolean values,
         * with each bit representing whether a number has been drawn (1) or not (0).
         * randomNumbersBitwise[0] is used to store the drawn number 0-255
         * randomNumbersBitwise[1] is used to store the drawn number 256-511
         * randomNumbersBitwise[2] is used to store the drawn number 512-767
         * and so on
         */
        uint256[] memory randomNumbersBitwise = new uint256[]((maxNumber >> 8) + 1);

        // Exclude 0 from the random numbers
        randomNumbersBitwise[0] = 1;
        for (uint256 i = 0; i < count;) {
            uint256 draw;

            /*
             * Below assembly code is used to generate random numbers with the following steps:
             * 1. Load the block hash, count, i, nonce, and salt bytes into memory
             * 2. Generate a random number using keccak256 hash of the memory
             * 3. Calculate the index and mask for the randomNumbersBitwise array
             * 4. Load the drawn number from the randomNumbersBitwise array
             * 5. Check if the number has been drawn
             * 6. If the number has not been drawn, store the number in the randomNumbers array
             * 7. If the number has been drawn, increment the nonce, and repeat the process
             * 8. Repeat the process until the required number of random numbers are generated
             */
            assembly {
                let m := mload(0x40)
                mstore(m, blockHash)
                mstore(add(m, 0x20), count)
                mstore(add(m, 0x40), i)
                mstore(add(m, 0x60), nonce)
                mstore(add(m, 0x80), saltBytes)
                draw := mod(keccak256(m, 0xa0), maxNumber)

                let index := add(shr(8, draw), 1)
                let mask := shl(and(draw, 0xff), 1)
                let drawnNumber := mload(add(randomNumbersBitwise, mul(0x20, index)))

                switch and(drawnNumber, mask)
                case 0 {
                    mstore(add(randomNumbers, mul(0x20, add(i, 1))), draw)
                    mstore(add(randomNumbersBitwise, mul(index, 0x20)), or(drawnNumber, mask))
                    i := add(i, 1)
                }
                default { nonce := add(nonce, 1) }
            }
        }
        return randomNumbers;
    }
}
