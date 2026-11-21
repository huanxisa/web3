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
 * Day 4 待实现：Aave V3 borrow（借出资产）+ getUserAccountData（健康因子）。
 *
 * Aave Pool.sol 关键函数签名：
 *
 *   function borrow(
 *       address asset,          // 借哪个 token
 *       uint256 amount,
 *       uint256 interestRateMode,  // 1=stable, 2=variable（V3 几乎只用 variable）
 *       uint16  referralCode,
 *       address onBehalfOf
 *   ) external;
 *
 *   function getUserAccountData(address user) external view returns (
 *       uint256 totalCollateralBase,
 *       uint256 totalDebtBase,
 *       uint256 availableBorrowsBase,
 *       uint256 currentLiquidationThreshold,
 *       uint256 ltv,
 *       uint256 healthFactor    // ← 关键：< 1e18 时该用户被清算
 *   );
 *
 * Day 4 任务：
 *   1. 实现 borrow()
 *   2. 实现 getHealthFactor(address user)
 *   3. 在 controller 加一个 /api/user/{addr}/health 端点
 *   4. 在测试网制造一笔抵押 + 借款，验证 healthFactor 数值合理
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AaveBorrowService {

    private final Web3j web3j;
    private final Credentials credentials;
    private final ContractGasProvider gasProvider;
    private final AaveProperties aaveProperties;

    public String borrow(String tokenSymbol, BigInteger amount) {
        log.warn("[TODO Day 4] borrow({}, {})", tokenSymbol, amount);
        return "TODO";
    }

    public BigInteger getHealthFactor(String userAddress) {
        log.warn("[TODO Day 4] getHealthFactor({})", userAddress);
        return BigInteger.ZERO;
    }
}
