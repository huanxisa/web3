package com.example.aaveadapter.controller;

import com.example.aaveadapter.service.AaveBorrowService;
import com.example.aaveadapter.service.AaveSupplyService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigInteger;
import java.util.Map;

@RestController
@RequestMapping("/api/aave")
@RequiredArgsConstructor
public class AaveController {

    private final AaveSupplyService supplyService;
    private final AaveBorrowService borrowService;

    /**
     * 调用示例（Day 3 完成后）：
     *   curl -X POST http://localhost:8080/api/aave/supply \
     *        -H "Content-Type: application/json" \
     *        -d '{"token":"usdc","amount":"100000000"}'   // 100 USDC = 100 * 10^6
     */
    @PostMapping("/supply")
    public Map<String, String> supply(@RequestBody SupplyRequest req) {
        String txHash = supplyService.supply(req.token(), new BigInteger(req.amount()));
        return Map.of("txHash", txHash, "status", "submitted");
    }

    @PostMapping("/borrow")
    public Map<String, String> borrow(@RequestBody SupplyRequest req) {
        String txHash = borrowService.borrow(req.token(), new BigInteger(req.amount()));
        return Map.of("txHash", txHash, "status", "submitted");
    }

    /**
     * 调用示例（Day 4 完成后）：
     *   curl http://localhost:8080/api/aave/user/0xYourAddress/health
     */
    @GetMapping("/user/{addr}/health")
    public Map<String, Object> getHealth(@PathVariable("addr") String userAddress) {
        BigInteger hf = borrowService.getHealthFactor(userAddress);
        return Map.of(
                "user", userAddress,
                "healthFactor", hf,
                "danger", hf.compareTo(BigInteger.valueOf(1_000_000_000_000_000_000L)) < 0
        );
    }

    public record SupplyRequest(String token, String amount) {}
}
