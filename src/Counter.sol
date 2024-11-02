// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./lib/TickMath.sol";
import {console} from "forge-std/console.sol";

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
        console.log("setNumber:", newNumber);
    }

    function increment() public {
        number++;
    }

    /*
        https://optimistic.etherscan.io/address/0x8323d063b1d12acce4742f1e3ed9bc46d71f4222#readContract

        Possible values of slot0 in the pool:
                                    
        sqrtPriceX96   uint160 :    79226793319386088693172751280512572                        
                        found:      79224096675729282467262434437247954
        tick   int24 :  276323

        sqrtPriceX96   uint160 :    79231163915643465547832199123538643
                       found:       79228057781537899283318961129827820
        tick   int24 :  276324

        OUT OF RANGE:
        sqrtPriceX96   uint160 :  79232242665933325995180086050260868
        tick   int24 :  276325     

        OUT OF RANGE:
        sqrtPriceX96   uint160 :  79215778990782115210812504314000126
        tick   int24 :  276320  
    */

    function calc() public {
        int24 min_tick = -887272;
        int24 max_tick = 887272;

        uint160 min_res = TickMath.getSqrtRatioAtTick(min_tick);
        console.log("sqrtRatio at min tick:", min_res);

        int24 tick = 276323;
        uint160 res = TickMath.getSqrtRatioAtTick(tick);
        console.log("sqrtRatio found:", res);

        uint160 sqrtPriceX96 = 79231163915643465547832199123538643;
        int24 foundTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        console.log("tick found:", foundTick);
    }
}
