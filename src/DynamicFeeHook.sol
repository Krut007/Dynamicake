// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@pancakeswap/v4-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "@pancakeswap/v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {LPFeeLibrary} from "@pancakeswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {CLBaseHook} from "./pool-cl/CLBaseHook.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SD59x18 } from "@prb/math/src/SD59x18.sol";
import { UD60x18, convert, wrap, div, floor} from "@prb/math/src/UD60x18.sol";

/// @notice CLCounterHook is a contract that counts the number of times a hook is called
/// @dev note the code is not production ready, it is only to share how a hook looks like
contract DynamicFeeHook is CLBaseHook {
    using PoolIdLibrary for PoolKey;


    struct param {
        uint24 baseFactor;
        uint24 binStep;
        uint24 constantA;
        uint24 constantR;
        uint24 filterPeriod;
        uint24 decayPeriod;
    }
    

    mapping(PoolId => uint24 fee) public poolBaseFactor;
    mapping(PoolId => uint24 volatility) public poolVolatilityAccumulator;
    mapping(PoolId => uint24 binStep) public poolBinStep;
    mapping(PoolId => uint24 currentBin) public poolCurrentBin;
    mapping(PoolId => uint256 filterPeriod) public poolFilterPeriod;
    mapping(PoolId => uint256 decayPeriod) public poolDecayPeriod;
    mapping(PoolId => uint256 lastSwapTime) public poolLastSwap;
    mapping(PoolId => uint24 indexReference) public poolIndexReference;
    mapping(PoolId => uint24 volatilityReference) public poolVolatilityReference;
    mapping(PoolId => uint24 constantR) public poolConstantR;
    mapping(PoolId => uint24 constantA) public poolConstantA;
    

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

    function afterInitialize(address, PoolKey calldata key, uint160, int24, bytes calldata swapRawData)
        external
        override 
        returns (bytes4)
    {
        param memory swapData = abi.decode(swapRawData, (param));


        poolVolatilityReference[key.toId()] = 0;
        poolVolatilityAccumulator[key.toId()] = 0;



        poolBinStep[key.toId()] = swapData.binStep;
        poolBaseFactor[key.toId()] = swapData.baseFactor;
        poolDecayPeriod[key.toId()] = swapData.decayPeriod;
        poolFilterPeriod[key.toId()] = swapData.filterPeriod;
        poolConstantA[key.toId()] = swapData.constantA;
        poolConstantR[key.toId()] = swapData.constantR;
        poolLastSwap[key.toId()] = block.timestamp;

        return this.afterInitialize.selector;
    }


    function beforeSwap(address, PoolKey calldata key, ICLPoolManager.SwapParams calldata dt, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4, BeforeSwapDelta, uint24)
    {

        uint deltaTime = block.timestamp - poolLastSwap[key.toId()];
        poolLastSwap[key.toId()] = block.timestamp;


        //TODO
        //Number of tick the swap is spanning across
        int256 k = 2;

        uint24 baseFee = baseFee(key.toId());
        uint24 dynamicFee = dynamicFee(key.toId(), deltaTime, k);

        uint24 lpFee = (baseFee);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, lpFee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }

    //Good
    function baseFee(PoolId id) internal returns (uint24){
        return (poolBaseFactor[id] * poolBinStep[id])/(10**6);
    }

    //Good
    function dynamicFee(PoolId id, uint256 time, int256 k) internal returns (uint24){
        return uint24((poolConstantA[id]*(((volatilityAccumulator(id, k, time)+poolBinStep[id])**2)/(10**6)))/(10**6));
    }

    //Good
    function indexReference(uint256 time, PoolId id) internal returns(uint24){
        if (time>=poolFilterPeriod[id]){
            poolIndexReference[id] = poolCurrentBin[id];
        }
        return poolIndexReference[id];
    }

    //Good
    function volatilityReference(uint time, PoolId id) internal returns(uint24){
        if (time>=poolDecayPeriod[id]){
            poolVolatilityReference[id] = 0;
        } else if (time>=poolFilterPeriod[id]){
            poolVolatilityReference[id] = (poolConstantR[id] * poolVolatilityAccumulator[id])/(10**6);
        }
        return poolVolatilityReference[id];
    }

    //Good
    function volatilityAccumulator(PoolId id, int256 k, uint256 time) internal returns(uint24){
        poolVolatilityAccumulator[id] = volatilityReference(time, id)+uint24(SignedMath.abs(SafeCast.toInt256(indexReference(time, id))-(SafeCast.toInt256(poolCurrentBin[id])+k)));
        return poolVolatilityAccumulator[id];
    }

    //Good
    /*
    function getIdFromRatio(uint256 unsignedRatio, PoolId id) internal returns(uint256) {
        UD60x18 ratio = convert(unsignedRatio);
        UD60x18 price = div(ratio,convert(uint256()));
        UD60x18 logPrice = price.log2();
        UD60x18 logStep = wrap(uint256(1*(10**18)+1*(10**12))).log2();
        UD60x18 divResult = div(logPrice, logStep);
        UD60x18 tronc = floor(divResult);
        uint256 unsignedTronc = convert(tronc);
        return unsignedTronc+8388608;
    }
    */
}