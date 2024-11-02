// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./lib/TickMath.sol";
import "./lib/interfaces/INonfungiblePositionManager.sol";
import "./lib/interfaces/IUniswapV3Pool.sol";
import {console} from "forge-std/console.sol";
import "solmate/utils/FixedPointMathLib.sol";

contract Deposit {
    struct PoolSlot {        
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;        
    }

    uint256 constant WAD = 1e10;  // can fit under uint64
    uint256 constant WAD2 = 1e5;
    int24 public constant MIN_TICK = -887272;
    int24 public constant MAX_TICK = 887272;
    uint16 constant K = 10000;
    uint256 constant Q96 = 2**96;
    uint256 constant Q48 = 2**48;
    uint256 constant Q24 = 2**24;
    address internal constant NON_FUNGIBLE_POS_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    function createPosition(address poolAddress, uint256 amount0Desired, uint256 amount1Desired, uint16 width, uint256 deadline) external returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ) {
            IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
            (uint160 sqrtPriceX96, int24 tick, , , , , )  = pool.slot0();

            console.log("tick:", tick);
            console.log("sqrtPriceX96:", sqrtPriceX96);

            (int24 tickLower, int24 tickUpper) = this.calculate(amount0Desired, amount1Desired, width, sqrtPriceX96);

            INonfungiblePositionManager.MintParams memory params;
            params.token0 = pool.token0();
            params.token1 = pool.token1();
            params.fee = pool.fee();
            params.recipient = 0xB0b12f40b18027f1a2074D2Ab11C6e0d6c6acbB5;
            params.amount0Desired = amount0Desired;
            params.amount1Desired = amount1Desired;
            params.tickLower = tickLower;
            params.tickUpper = tickUpper;
            params.deadline = deadline;

            INonfungiblePositionManager manager = INonfungiblePositionManager(NON_FUNGIBLE_POS_MANAGER);            
            return manager.mint(params);
    }

    function calculate(uint256 x, uint256 y, uint16 width, uint160 sqrtPriceX96) external view returns (
        int24 tickLower,
        int24 tickUpper
    ) {
        require (x > 0 || y > 0, "at least one token must be deposited");
        require (width <= K, "width less or equal to K");

        if (width == K) {   // max value of width means we put in all range
            return (MIN_TICK, MAX_TICK);
        }

        uint256 a_fp = ((width + K) * WAD) / (K - width);
        
        /* a_fp is in range [0;19999] before WAD multiply */

        uint256 b_fp = (x*sqrtPriceX96*WAD)/Q96;

        console.log("a_fp:", a_fp);
        console.log("b_fp:", b_fp);

        uint256 max = 2**256-1;
        console.log("max:", max);

        uint160 sqrtPriceHighX96 = this.solveQuadratic(a_fp, b_fp, sqrtPriceX96, y);

        // Then we calculate
        // Pl=Ph/a => sqrt(Pl)=sqrt(Ph)/sqrt(a)

        uint256 sqrt_a_fp = FixedPointMathLib.sqrt(a_fp)*WAD2;
        uint256 sqrtPriceLowX96_uint256 = (uint256(sqrtPriceHighX96) * WAD) / sqrt_a_fp;
        require (sqrtPriceLowX96_uint256 <= 2**160 - 1);
        uint160 sqrtPriceLowX96 = uint160(sqrtPriceLowX96_uint256);

        console.log("sqrtPriceLowX96: ", sqrtPriceLowX96);
        console.log("sqrtPriceHighX96:", sqrtPriceHighX96);

        tickLower = TickMath.getTickAtSqrtRatio(sqrtPriceLowX96);
        tickUpper = TickMath.getTickAtSqrtRatio(sqrtPriceHighX96);
    }

    function solveQuadratic(uint256 a_fp, uint256 b_fp, uint160 sqrtPriceX96, uint256 y) external pure returns (
        uint160 sqrtPriceHighX96
    ) {
        console.log("y:", y);

        uint256 sqrt_a_fp = FixedPointMathLib.sqrt(a_fp)*WAD2;
        console.log("sqrt_a_fp:", sqrt_a_fp);

        uint256 sqrtPriceX96Int = sqrtPriceX96;

        int256 A_fp = int256(b_fp);
        console.log("+A_fp:", A_fp);
        
        int256 B_fp = int256(sqrt_a_fp*y) - int256(((sqrt_a_fp*b_fp) / WAD) * sqrtPriceX96 / Q96);
        console.log("+B_fp:", B_fp);

        int256 C_fp = -int256(sqrt_a_fp)*int256(sqrtPriceX96Int)*int256(y)/int256(Q96);       
        console.log("+C_fp:", C_fp);

        int256 discriminant_fp = int256(uint256(B_fp**2) / WAD) - 4*A_fp*C_fp/int256(WAD);
        console.log("+discriminant_fp:", discriminant_fp);
        require (discriminant_fp >= 0, "must be real roots");

        int256 d_square_fp = int256(FixedPointMathLib.sqrt(uint256(discriminant_fp))) * int256(WAD2);
        console.log("d_square_fp:", d_square_fp);

        int256 z1_fp;
        int256 z2_fp;
        if (A_fp != 0) {    // two roots
            z1_fp = int256(WAD) * (-B_fp + d_square_fp) / 2 / A_fp;
            z2_fp = int256(WAD) * (-B_fp - d_square_fp) / 2 / A_fp;
            console.log("+z1_fp: ", z1_fp);
            console.log("+z2_fp: ", z2_fp);
        } else {            // one root
            z1_fp = -C_fp*int256(WAD) / B_fp;
            console.log("+z_fp: ", z1_fp);
        }

        require (z1_fp > 0 || z2_fp > 0, "must be positive solution");

        uint256 sqrtPriceHigh_fp;
        if (z1_fp > 0) {
            sqrtPriceHigh_fp = uint256(z1_fp);
        }
        else {
            sqrtPriceHigh_fp = uint256(z2_fp);
        }

        uint256 sqrtPriceHighX96_uint256 = (sqrtPriceHigh_fp * Q96) / WAD;

        require (sqrtPriceHighX96_uint256 <= 2**160-1, "sqrtPriceHighX96_uint256");
        sqrtPriceHighX96 = uint160(sqrtPriceHighX96_uint256);
    }
}
