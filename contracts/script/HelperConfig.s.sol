// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        string name;
        uint256 privateKey;
        uint256 gasPrice;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getAnvilConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                name: "anvil",
                privateKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80,
                gasPrice: 20000000000 // 20 gwei
            });
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                name: "sepolia",
                privateKey: vm.envUint("PRIVATE_KEY"), // Use the environment variable PRIVATE_KEY
                gasPrice: 10000000000 // 10 gwei
            });
    }
    function getMainnetConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                name: "mainnet",
                privateKey: vm.envUint("PRIVATE_KEY"),
                gasPrice: 50000000000 // 50 gwei
            });
    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
