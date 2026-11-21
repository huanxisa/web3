package com.example.aaveadapter.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.Map;

@Data
@Configuration
@ConfigurationProperties(prefix = "aave")
public class AaveProperties {
    private String network;
    private String rpcUrl;
    private String poolAddressesProvider;
    private String pool;
    private String uiPoolDataProvider;
    private Map<String, String> tokens;
}
