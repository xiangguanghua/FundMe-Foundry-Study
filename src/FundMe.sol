// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe {
    /**
    让所有uint256类型的变量都可以调用 PriceConverter 库中的方法。
    例如 msg.value 是 uint256，因此可以直接调用 getConversionRate 方法。
     */
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded; // 记录投资者=>投资金额
    address[] private s_funders; //投资者列表

    address private immutable i_owner; // 什么合约所有者
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18; // 最小投资金额
    AggregatorV3Interface private s_priceFeed; // 声明语言机接口

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /***转入资金，payable表示可以接受以太币
    fund函数是用 payable 修饰的,当用户调用 fund() 函数并发送以太币时，这些以太币会通过 msg.value 进入到合约中。
    msg.value 中的以太币会自动转入合约地址。每当有资金发送到合约时，合约的余额（address(this).balance）会自动增加
    */
    function fund() public payable {
        /** using PriceConverter for uint256; 引入的库，让uint256类型的变量可以调用 PriceConverter 库中的方法.
        并且msg.value作为方法的第一个参数传入其中*/
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        s_addressToAmountFunded[msg.sender] += msg.value; //合约调用者为投资者，投资金额为msg.value
        s_funders.push(msg.sender); // 加入投资者列表
    }

    /**
    获取语言机版本，获取预言机价格的版本信息主要用于以下目的：
    1、兼容性验证
        不同版本的预言机合约可能存在接口差异（如函数参数、返回值结构等）
        通过版本号可验证当前使用的预言机是否符合预期接口标准
    2、数据源可信度确认
        版本升级可能伴随数据源节点变更或聚合算法改进
        高版本号通常意味着更稳定的数据源和更安全的预言机配置
    3、故障排查与监控
        当价格异常时，版本号可帮助快速定位是否为预言机升级导致的问题
        便于监控系统记录不同版本预言机的运行表现
    4、升级管理
        智能合约可通过版本号检测预言机升级事件
        触发自动迁移逻辑或通知管理员进行人工验证
     */
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // 验证合约所有者
        if (msg.sender != i_owner) revert FundMe_NotOwner();
        _;
    }

    //提现：只有合约所有者才可以可以提现
    function withdraw() public onlyOwner {
        // 遍历所有投资者，将投资金额清零
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex]; // 找都投资者
            s_addressToAmountFunded[funder] = 0; // 将投资者的投资金额清零
        }
        s_funders = new address[](0); // 清空投资者列表
        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // 使用call转账
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    /**Gas优化 */
    function cheaperWithdraw() public onlyOwner {
        uint256 fundersCount = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersCount;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    /**********get方法********** */

    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}
