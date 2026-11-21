package com.example.aaveadapter.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.web3j.crypto.Credentials;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.http.HttpService;
import org.web3j.tx.gas.ContractGasProvider;
import org.web3j.tx.gas.DefaultGasProvider;

import java.math.BigInteger;

/**
 * web3j 核心配置：连 Sepolia + 提供操作员凭证。
 *
 * Day 1 任务：本类跑通 → 在启动日志里打印 Sepolia 当前 blockNumber。
 */
@Configuration
public class Web3jConfig {

    private final AaveProperties aaveProperties;

    @Value("${wallet.private-key:}")
    private String walletPrivateKey;

    public Web3jConfig(AaveProperties aaveProperties) {
        this.aaveProperties = aaveProperties;
    }

    @Bean
    public Web3j web3j() {
        return Web3j.build(new HttpService(aaveProperties.getRpcUrl()));
    }

    @Bean
    public Credentials credentials() {
        if (walletPrivateKey == null || walletPrivateKey.isBlank()) {
            return Credentials.create("0x0000000000000000000000000000000000000000000000000000000000000001");
        }
        return Credentials.create(walletPrivateKey);
    }

    /**
     * Day 4 待实现：用动态 gas 估算替代 DefaultGasProvider。
     * 目前先用默认值跑通流程。
     */
    @Bean
    public ContractGasProvider gasProvider() {
        return new DefaultGasProvider() {
            @Override
            public BigInteger getGasLimit(String contractFunc) {
                return BigInteger.valueOf(800_000L);
            }
        };
    }
}
