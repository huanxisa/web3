package com.example.aaveadapter.event;

import com.example.aaveadapter.config.AaveProperties;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameter;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.request.EthFilter;

/**
 * Day 5 待实现：监听 Aave 清算事件。
 *
 * Aave Pool 上 LiquidationCall event 的 Solidity 签名：
 *
 *   event LiquidationCall(
 *       address indexed collateralAsset,
 *       address indexed debtAsset,
 *       address indexed user,             // 被清算的用户
 *       uint256 debtToCover,
 *       uint256 liquidatedCollateralAmount,
 *       address liquidator,               // 清算人
 *       bool    receiveAToken
 *   );
 *
 * Day 5 任务：
 *   1. 用 web3j 的 EthFilter 订阅这个 event
 *   2. 接收到 event 后落地 PostgreSQL（先用 H2 内存库）
 *   3. 校验在 Sepolia 测试网能收到至少 1 笔真实清算事件（参考 etherscan）
 *
 * 关键点（面试常问）：
 *   - 为什么需要 finalized block？→ 防 reorg，应该等 12-32 个确认
 *   - 怎么处理服务重启？→ 持久化 lastProcessedBlock
 *   - 怎么避免漏块？→ 用区块号 range query 而不是 subscribe
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LiquidationListener {

    private final Web3j web3j;
    private final AaveProperties aaveProperties;

    @Value("${liquidation-listener.enabled:true}")
    private boolean enabled;

    @PostConstruct
    public void start() {
        if (!enabled) {
            log.info("LiquidationListener disabled by config");
            return;
        }
        log.warn("[TODO Day 5] LiquidationListener.start() - subscribe to Aave Pool {}",
                aaveProperties.getPool());

        // 实现伪代码：
        // EthFilter filter = new EthFilter(
        //         DefaultBlockParameterName.LATEST,
        //         DefaultBlockParameterName.LATEST,
        //         aaveProperties.getPool()
        // ).addSingleTopic(EventEncoder.encode(LIQUIDATION_CALL_EVENT));
        // web3j.ethLogFlowable(filter).subscribe(this::handleLog, Throwable::printStackTrace);
    }
}
