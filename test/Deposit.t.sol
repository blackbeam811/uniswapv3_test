// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Deposit} from "../src/Deposit.sol";
import {console} from "forge-std/console.sol";
import "solmate/utils/FixedPointMathLib.sol";

contract DepositTest is Test {
    address constant OPTIMISM_USDT_DAI_POOL = 0x8323D063b1D12ACce4742f1E3ed9BC46d71f4222;
    Deposit public deposit;

    function setUp() public {
        deposit = new Deposit();
    }

    // function test_CreatePosition() public {
    //     // from tx 0x3c6da60ab1f78c635a9a27a84163c0ec628111c370d2073246e44adf728a3322
    //     deposit.createPosition(OPTIMISM_USDT_DAI_POOL, 1878690348, 1598506205772095349654, 1000, 999999999999);
    // }

    /* 
        An example values from 
        https://ethereum.stackexchange.com/questions/99425/calculate-deposit-amount-when-adding-to-a-liquidity-pool-in-uniswap-v3

        1 ETH - 2907 USDC
        width 2012 (calculated postfactum)
        sqrtPriceX96 is int(math.sqrt(price)*q96) (Python calculated)
    */
    function test_Calc_SO_example() view public {
        (int24 tickLower, int24 tickUpper) = deposit.calculate(1, 2907, 2012, 3950936166981137000000000000000);
        console.log("tickLower:", tickLower);
        console.log("tickUpper:", tickUpper);

        assertEq(tickLower, 75984);
        assertEq(tickUpper, 80064);
        /* test
                Math.pow(1.0001, 75984)  -> 1994.24359156
                Math.pow(1.0001, 80064)  -> 2998.89662006
         */
    }

    /*
        tx https://optimistic.etherscan.io/tx/0x3c6da60ab1f78c635a9a27a84163c0ec628111c370d2073246e44adf728a3322
        Pool https://optimistic.etherscan.io/address/0x8323d063b1d12acce4742f1e3ed9bc46d71f4222#readContract (USDT 6 dec, DAI 18 DEC)
            tickLower: 276322 (price  999797386698)
            tickUpper: 276325 (price 1000097355911)
        width = (1000097355911-999797386698)*10000/(1000097355911+999797386698) = 1.4999
     */
    function test_Calc_Real1() view public {
        (int24 tickLower, int24 tickUpper) = deposit.calculate(1878309817, 1598506205772095349653, 1, 79225599211828132685397853080702016);
        console.log("tickLower:", tickLower);
        console.log("tickUpper:", tickUpper);

        // almost the same as in tx above, but a bit narrower
        assertEq(tickLower, 276322);
        assertEq(tickUpper, 276324);

        (tickLower, tickUpper) = deposit.calculate(1878690348, 1598506205772095349654, 2, 79225599211828132685397853080702016);
        console.log("tickLower:", tickLower);
        console.log("tickUpper:", tickUpper);

        // almost the same as in tx above, but a bit wider
        assertEq(tickLower, 276321);
        assertEq(tickUpper, 276325);
    }

    /* 
        Optimism tx 0x7e3d0d50b7a684b4ac919cd0ec879002525fd958b9724b27218cff5140569d07
        pool https://optimistic.etherscan.io/address/0x85c31ffa3706d1cce9d525a00f1c7d4a2911754c - (WETH 18 dec, WBTC 8 dec)

        Low -262370  price Math.pow(1.0001, -262370) = 0.0000000000040363179524189 -> 0.040363179524189 WBTC for ETH
        Upp -262290  price Math.pow(1.0001, -262290) = 0.0000000000040687363759487 -> 0.040687363759487 WBTC for ETH

        width = (0.040687363759487-0.040363179524189)*10000/(0.040687363759487+0.040363179524189) = 39.997
    */
    function test_Calc_RealToken1DesiredZero() view public {
        (int24 tickLower, int24 tickUpper) = deposit.calculate(4097853923833107646, 0, 40, 159129345196923573373921);
        console.log("tickLower:", tickLower);
        console.log("tickUpper:", tickUpper);

        // almost the same as in tx above
        // price diff (Math.pow(1.0001, -262376)-Math.pow(1.0001, -262370)).toFixed(25)=0.0000000000000024209433707 
        // => 0.000024209433707 decimals accounted ~ $1.5 price difference (should be fine)
        assertEq(tickLower, -262376);
        assertEq(tickUpper, -262297);
    }

    /* tx https://optimistic.etherscan.io/tx/0x585741cdf7b136487c9c0c2ea322867f001ec8fa13fa464c91e049b2f3f9aa29
        pool https://optimistic.etherscan.io/address/0x1fb3cf6e48f1e7b10213e7b6d87d4c073c7fdb7b#readContract (USDC 0 dec - WETH 18 dec)
        lower  197690 price Math.pow(1.0001, 197690)=384714329.63672894 -> human 0.00000000038471432963672894 WETH for USDC
        uppper 197760 price Math.pow(1.0001, 197760)=387416641.88982975 -> 
        width = 34.99
    */
    function test_Calc_RealToken0DesiredZero() view public {
        (int24 tickLower, int24 tickUpper) = deposit.calculate(0, 1111747511608980342, 35, 1560713875195378972064713040461824);
        console.log("tickLower:", tickLower);
        console.log("tickUpper:", tickUpper);

        assertEq(tickLower, 197706);
        assertEq(tickUpper, 197776);
    }

    // Testing boundary cases - too low / too high input values.
    function test_Calc_BoundaryCases() public {
        int24 tickLower; 
        int24 tickUpper;

        vm.expectRevert("at least one token must be deposited");
        deposit.calculate(0, 0, 35, 1560713875195378972064713040461824);

        vm.expectRevert("width less or equal to K");
        deposit.calculate(1, 1, 10000+1, 1560713875195378972064713040461824);

        // zero width – put in the same tick
        (tickLower, tickUpper) = deposit.calculate(0, 1111747511608980342, 0, 1560713875195378972064713040461824);
        assertEq(tickLower, tickUpper);

        // max width for the full price range
        (tickLower, tickUpper) = deposit.calculate(0, 1111747511608980342, 10000, 1560713875195378972064713040461824);
        assertEq(tickLower, deposit.MIN_TICK());
        assertEq(tickUpper, deposit.MAX_TICK());


        (tickLower, tickUpper) = deposit.calculate(1e17, 1e24, 10000-1, 2**110-1);
    }
}
