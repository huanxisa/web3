package com.example.aaveadapter.service;

import com.example.aaveadapter.config.AaveProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.web3j.crypto.Credentials;
import org.web3j.protocol.Web3j;
import org.web3j.tx.gas.ContractGasProvider;

import java.math.BigInteger;

/**
 * Day 3 待实现：Aave V3 supply（存抵押品）。
 *
 * Aave Pool.sol 的核心函数签名（你只读不写，但要看懂）：
 *
 *   function supply(
 *       address asset,        // 要存的 token，如 USDC
 *       uint256 amount,       // 数量（注意精度，USDC 是 6 位）
 *       address onBehalfOf,   // 受益人地址（一般 = msg.sender）
 *       uint16  referralCode  // 通常传 0
 *   ) external;
 *
 * 调用前必须：
 *   1. token.approve(poolAddress, amount)  ← 授权 Pool 合约扣你的 token
 *   2. Pool.supply(...)
 *
 * Day 3 任务步骤：
 *   1. 用 web3j-codegen 从 Aave Pool ABI 生成 Pool.java（命令在 contract/README.md）
 *   2. 用 ERC20.java 标准 binding 调用 token.approve()
 *   3. 调用 pool.supply(...).send()
 *   4. 在测试网用 100 USDC 跑通整个流程，校验你的 aUSDC 余额上涨
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AaveSupplyService {

    private final Web3j web3j;
    private final Credentials credentials;
    private final ContractGasProvider gasProvider;
    private final AaveProperties aaveProperties;

    /**
     * Day 3 占位：留待实现
     */
    public String supply(String tokenSymbol, BigInteger amount) {
        String tokenAddress = aaveProperties.getTokens().get(tokenSymbol);
        if (tokenAddress == null) {
            throw new IllegalArgumentException("Unknown token: " + tokenSymbol);
        }

        log.warn("[TODO Day 3] supply({}, {}) on Aave Pool {}",
                tokenSymbol, amount, aaveProperties.getPool());

        // 实现伪代码：
        // ERC20 token = ERC20.load(tokenAddress, web3j, credentials, gasProvider);
        // token.approve(aaveProperties.getPool(), amount).send();
        // Pool pool = Pool.load(aaveProperties.getPool(), web3j, credentials, gasProvider);
        // TransactionReceipt receipt = pool.supply(tokenAddress, amount,
        //         credentials.getAddress(), BigInteger.ZERO).send();
        // return receipt.getTransactionHash();

        return "TODO";
    }
}
