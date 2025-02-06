//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

/**
 * chainlink 的 price feed 配置,不同的网络配置不同的 price feed
 
 */
contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig; //用于存储当前活跃的网络配置，包括价格预言机的地址

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // 用于存储价格预言机的地址
    }

    /**
    当使用fork-url时，Foundry会连接到提供的RPC URL，
    获取该网络的最新区块数据，并在本地创建一个分叉环境。
    这样，合约在部署时会继承该网络的chainid，因为分叉环境复制了原网络的链ID。
     */
    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }
    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }
    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        // 如果 activeNetworkConfig.priceFeed 不为零地址，直接返回 activeNetworkConfig
        if (activeNetworkConfig.priceFeed != address(0)) {
            //如果不是零地址，表示已经有一个有效的配置，直接返回
            return activeNetworkConfig;
        }

        // 开始广播交易（用于本地测试环境）
        vm.startBroadcast();
        // 创建一个新的 MockV3Aggregator 实例，传入 DECIMALS 和 INITIAL_PRICE
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        // 停止广播交易
        vm.stopBroadcast();
        // 创建一个 NetworkConfig 实例，使用 mockPriceFeed 的地址
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        // 返回创建的 NetworkConfig 实例
        return anvilConfig;
    }
}
