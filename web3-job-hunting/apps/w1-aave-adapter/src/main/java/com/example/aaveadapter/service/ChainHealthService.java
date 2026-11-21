package com.example.aaveadapter.service;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.response.EthBlock;

import java.math.BigInteger;

/**
 * Day 1 启动校验：连接 Sepolia 并打印当前区块号。
 *
 * 启动后日志应该看到：
 *   [ChainHealthService] Connected to Sepolia, latestBlock=xxxxxx
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ChainHealthService {

    private final Web3j web3j;

    @PostConstruct
    public void checkChainConnection() {
        try {
            BigInteger latestBlock = web3j.ethBlockNumber().send().getBlockNumber();
            EthBlock block = web3j.ethGetBlockByNumber(DefaultBlockParameterName.LATEST, false).send();
            String chainId = web3j.ethChainId().send().getChainId().toString();
            log.info("✓ Connected. chainId={} latestBlock={} blockHash={}",
                    chainId, latestBlock, block.getBlock().getHash());
        } catch (Exception e) {
            log.error("✗ Failed to connect to RPC: {}", e.getMessage());
            log.error("  Check application.yml -> aave.rpc-url, " +
                      "or set env SEPOLIA_RPC_URL to a real Alchemy/Infura key");
        }
    }
}
