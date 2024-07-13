// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@pancakeswap/v4-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "@pancakeswap/v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {LPFeeLibrary} from "@pancakeswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {CLBaseHook} from "./pool-cl/CLBaseHook.sol";

/// @notice CLCounterHook is a contract that counts the number of times a hook is called
/// @dev note the code is not production ready, it is only to share how a hook looks like
contract CLCounterHook is CLBaseHook {
    using PoolIdLibrary for PoolKey;

    

    mapping(PoolId => uint24 fee) public poolBaseFactor;
    mapping(PoolId => uint volatility) public poolVolatility;
    mapping(PoolId => uint binStep) public poolBinStep;
    mapping(PoolId => uint currentBin) public poolCurrentBin;
    mapping(PoolId => uint filterPeriod) public poolFilterPeriod;
    mapping(PoolId => uint decayPeriod) public poolDecayPeriod;

    //mapping(address => int256 volume) public userVolume;
    
    constructor(ICLPoolManager _poolManager) CLBaseHook(_poolManager) {}

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: true,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: false,
                afterAddLiquidityReturnsDelta: false,
                afterRemoveLiquidityReturnsDelta: false
            })
        );
    }

    function afterInitialize(address, PoolKey calldata key, uint160, int24, bytes calldata poolData)
        external
        override 
        returns (bytes4)
    {
        //TODO implement
        poolVolatility[key.toId()] = 1;
        poolBinStep[key.toId()] = 5;




        uint24 swapFee = abi.decode(poolData, (uint24));
        poolBaseFactor[key.toId()] = swapFee;

        return this.afterInitialize.selector;
    }


    function beforeSwap(address, PoolKey calldata key, ICLPoolManager.SwapParams calldata dt, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        //userVolume[tx.origin] += int(data.amountSpecified);
        uint24 baseFee = baseFee(key.toId());
        uint24 dynamicFee = 0;

        uint24 lpFee = baseFee;



        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, lpFee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }

    function abs(int num) internal returns (uint){
        if (num<0){
            return uint(-num);
        } else {
            return uint(num);
        }
    }

    function baseFee(PoolId id) internal returns (uint24){
        return uint24(poolBaseFactor[id] * poolBinStep[id]);
    }
}
