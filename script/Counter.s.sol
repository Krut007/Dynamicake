// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Test} from "forge-std/Test.sol";
import {Constants} from "@pancakeswap/v4-core/test/pool-cl/helpers/Constants.sol";
import {Currency} from "@pancakeswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {DynamicFeeHook} from "../src/DynamicFeeHook.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLSwapRouterBase} from "@pancakeswap/v4-periphery/src/pool-cl/interfaces/ICLSwapRouterBase.sol";
import {LPFeeLibrary} from "@pancakeswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {console2} from "forge-std/console2.sol";
import {ICLPoolManager} from "@pancakeswap/v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";


contract CounterScript is Script {

    function setUp() public {
        

    }

    function run() public {
        /*
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DynamicFeeHook hook = new DynamicFeeHook(0x97e09cD0E079CeeECBb799834959e3dC8e4ec31A);
        PoolKey memory key = PoolKey({
            currency0: 0x912CE59144191C1204E64559FE8253a0e49E6548,
            currency1: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            hooks: hook,
            poolManager: 0x97e09cD0E079CeeECBb799834959e3dC8e4ec31A,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            parameters: bytes32(uint256(hook.getHooksRegistrationBitmap())).setTickSpacing(10)
        });
        DynamicFeeHook.param memory param = DynamicFeeHook.param({
            baseFactor: 10*(10**6),
            binStep: 5*(10**6),
            constantA: 1*(10**6),
            constantR: 0.5*(10**6),
            filterPeriod: 1*(10**6),
            decayPeriod: 2*(10**6)
        });
        0x97e09cD0E079CeeECBb799834959e3dC8e4ec31A.initialize(key, Constants.SQRT_RATIO_1_1, abi.encode(param));
        vm.stopBroadcast();
        */
    }
}
