//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe; // 声明待测试的合约

    /**
    makeAddr 是 Foundry 测试框架中提供的一个内置函数，它根据给定的字符串参数生成一个 20 字节的以太坊地址。
    这个生成过程是基于 字符串哈希 来创建的，确保给定相同的字符串，返回的地址始终相同。
    具体实现原理是通过 keccak256 哈希 函数对输入字符串进行哈希计算，并从哈希值中提取一个地址。
     */
    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1; //单位 wei

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        //console.log("DeployFundMe is msg.sender: ", msg.sender);
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); //给USER充值STARTING_BALANCE数量的ether
    }

    // 测试5美金是最小投资金额
    function testMinimumDollarIsFive() public view {
        console.log("Minimum USD: ", fundMe.MINIMUM_USD());
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    //测试合约所有者是部署合约的人
    function testOwnerIsMsgSender() public view {
        // user -> FundMeTest -> FundMe
        /**
            1、testOwnerIsMsgSender 是一个测试函数，它是由 FundMeTest 合约 调用的，而不是由 FundMe 合约 调用。
            2、msg.sender 在这个函数内是调用测试函数的账户（即测试的“用户”），通常是虚拟机默认的账户（例如 vm.addr(0)），而不是 FundMeTest 合约的地址。
            3、address(this) 返回的是 当前合约的地址，也就是 FundMeTest 合约的地址。
         */
        console.log("address(FundMeTest): ", address(this));
        console.log("address(FundMe)    : ", address(fundMe));
        console.log("Owner              : ", fundMe.getOwner());
        console.log("Sender             : ", msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // 测试priceFeed版本
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    // 测试获取的chainid
    function testGetChainId() public view {
        uint256 chainId = block.chainid;
        console.log("Current chainid:", chainId);
    }

    //测试更新投资者数据结构
    function testFundUpdatesFunderDataStructure() public funded {
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE); // 投资金额
        assertEq(fundMe.getFunders(0), USER);
    }

    // 测试投资者列表
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assertEq(fundMe.getFunders(0), USER);
    }

    // 定义存款函数
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // 测试只有合约拥有者才能提现
    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        // // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance // + gasUsed
        );
    }

    // 测试多个funder提取
    function testWithdrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        for (uint160 i = 1; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
    }

    //更便宜的提取
    function testWithdrawWithMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        for (uint160 i = 1; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
    }
}
