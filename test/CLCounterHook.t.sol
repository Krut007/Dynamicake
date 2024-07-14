// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
 
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Test} from "forge-std/Test.sol";
import {Constants} from "@pancakeswap/v4-core/test/pool-cl/helpers/Constants.sol";
import {Currency} from "@pancakeswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {DynamicFeeHook} from "../src/DynamicFeeHook.sol";
import {CLTestUtils} from "./utils/CLTestUtils.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLSwapRouterBase} from "@pancakeswap/v4-periphery/src/pool-cl/interfaces/ICLSwapRouterBase.sol";
import {LPFeeLibrary} from "@pancakeswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {console2} from "forge-std/console2.sol";

 
contract DynamicFeeHookTest is Test, CLTestUtils {
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;
 
    DynamicFeeHook aliceHook;
    DynamicFeeHook bobHook;
    Currency currency0;
    Currency currency1;
    PoolKey aliceKey;
    PoolKey bobKey;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
 
    function setUp() public {
        (currency0, currency1) = deployContractsWithTokens();
        aliceHook = new DynamicFeeHook(poolManager);
        bobHook = new DynamicFeeHook(poolManager);

 
        // create the pool key
        aliceKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: aliceHook,
            poolManager: poolManager,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            parameters: bytes32(uint256(aliceHook.getHooksRegistrationBitmap())).setTickSpacing(10)
        });

        bobKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: bobHook,
            poolManager: poolManager,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            parameters: bytes32(uint256(bobHook.getHooksRegistrationBitmap())).setTickSpacing(10)
        });

        DynamicFeeHook.param memory paramAlice = DynamicFeeHook.param({
            baseFactor: 5,
            binStep: 5,
            constantA: 1,
            constantR: 1,
            filterPeriod: 1,
            decayPeriod: 2
        });
 
        // initialize pool at 1:1 price point and set 3000 as initial lp fee, lpFee is stored in the hook
        poolManager.initialize(aliceKey, Constants.SQRT_RATIO_1_1, abi.encode(paramAlice));

        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);

        // add liquidity so that swap can happen
        MockERC20(Currency.unwrap(currency0)).mint(address(this), 200 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 200 ether);
        addLiquidity(aliceKey, 100 ether, 100 ether, -60, 60);
 
        DynamicFeeHook.param memory paramBob = DynamicFeeHook.param({
            baseFactor: 10,
            binStep: 5,
            constantA: 1,
            constantR: 1,
            filterPeriod: 1,
            decayPeriod: 2
        });
        // initialize pool at 1:1 price point and set 3000 as initial lp fee, lpFee is stored in the hook
        poolManager.initialize(bobKey, Constants.SQRT_RATIO_1_1, abi.encode(paramBob));

        // add liquidity so that swap can happen
        MockERC20(Currency.unwrap(currency0)).mint(address(this), 200 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 200 ether);
        addLiquidity(bobKey, 100 ether, 100 ether, -60, 60);
 



        // approve from alice for swap in the test cases below
        vm.startPrank(alice);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);
        vm.stopPrank();

        // approve from bob for swap in the test cases below
        vm.startPrank(bob);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);
        vm.stopPrank();
 
        // mint alice token for trade later
        MockERC20(Currency.unwrap(currency0)).mint(address(alice), 100 ether);

        // mint bob token for trade later
        MockERC20(Currency.unwrap(currency0)).mint(address(bob), 100 ether);
    }
 
 
    function testNonVeCakeHolderXX() public {
        uint256 amtOutAlice = _swapAlice();
        console2.log(amtOutAlice);
        uint256 amtOutBob = _swapBob();
        console2.log(amtOutBob);
        
        // amt out be at least 0.3% lesser due to swap fee
        assertLe(amtOutBob, amtOutAlice);
    }

    function _swapAlice() internal returns (uint256 amtOut) {
        // set alice as tx.origin
        vm.prank(address(alice), address(alice));
 
        amtOut = swapRouter.exactInputSingle(
            ICLSwapRouterBase.V4CLExactInputSingleParams({
                poolKey: aliceKey,
                zeroForOne: true,
                recipient: address(alice),
                amountIn: 1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0,
                hookData: new bytes(0)
            }),
            block.timestamp
        );
    }

    function _swapBob() internal returns (uint256 amtOut) {
        // set alice as tx.origin
        vm.prank(address(bob), address(bob));
 
        amtOut = swapRouter.exactInputSingle(
            ICLSwapRouterBase.V4CLExactInputSingleParams({
                poolKey: bobKey,
                zeroForOne: true,
                recipient: address(bob),
                amountIn: 1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0,
                hookData: new bytes(0)
            }),
            block.timestamp
        );
    }
}