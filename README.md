# 项目介绍

项目名：众筹项目。这是我学习智能合约过程中编写一个学习项目。<br>
技术项：Solidity + foundry + chainlink<br>
主要功能点：<br>
1、使用Chainlink的价格预言机来获取当前的ETH/USD汇率<br>
2、获取预言机版本号<br>
3、使用payable方法接受用户投资的ETH<br>
4、使用payable address提取合约资金<br>
5、通过网络部署助手HeplerConfig脚本，实现多网络部署<br>
6、全方位合约测试脚本<br>
7、使用foundry优化合约GAS<br>
8、使用MockV3Aggregator模拟预言机价格，在测试过程中能够模拟和控制预言机返回的数据，而不必依赖真实的 Chainlink 价格预言机<br>
9、使用Makefile文件命令行快捷测试部署<br>
