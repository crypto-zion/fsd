/*
    Copyright 2020 Freq Set Dollar <freqsetdollar@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./external/Decimal.sol";

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PERIOD = 2;
    uint256 private constant BOOTSTRAPPING_PRICE = 220e16; // 2.2 USDC (targeting 5% inflation)

    /* Oracle */
    address private constant USDC = address(0x28709Af9376191653bA671d3C74682cA6F46a4Fd);

    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 FSD -> 100M FSDS

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant EPOCH_OFFSET = 0;
    uint256 private constant EPOCH_START = 1609905600;
    
    uint256 private constant EPOCH_PERIOD = 120; // 2 min

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 24; // 24 epochs
    uint256 private constant GOVERNANCE_QUORUM = 20e16; // 20%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 6; // 6 epochs
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 1e16; // 1%

    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE = 1e20; // 100 FSD

    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 12; // 12 epochs fluid

    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 6; // 6 epochs fluid

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 720; //720 epoch

    uint256 private constant DEBT_RATIO_CAP = 50e16; // 50%

    uint256 private constant INITIAL_COUPON_REDEMPTION_PENALTY = 65e16; // 65%

    uint256 private constant COUPON_REDEMPTION_PENALTY_DECAY = 1800; // 30 minutes

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_DIVISOR = 24e18; // 24

    //10% supply limit 
    uint256 private constant SUPPLY_CHANGE_LIMIT = 10e16; // 10%

    uint256 private constant ORACLE_POOL_RATIO = 50; // 50%

    // bonds logic
    uint256 private constant BOND_REDEEMABLE_TWAP_CAP = 120e16; // 1.2USDC
    
    uint256 private constant BOND_REDEEMABLE_TWAP_FLOOR = 1e18; // 1USDC

    //bond pool : coupon pool = 4:1
    uint256 private constant BOND_POOL_RATIO = 80; // 80%


    /**
     * Getters
     */

    function getUsdcAddress() internal pure returns (address) {
        return USDC;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: EPOCH_OFFSET,
            start: EPOCH_START,
            period: EPOCH_PERIOD
        });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }

    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }

    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE;
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }

    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }

    function getInitialCouponRedemptionPenalty() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: INITIAL_COUPON_REDEMPTION_PENALTY});
    }
    function getCouponRedemptionPenaltyDecay() internal pure returns (uint256) {
        return COUPON_REDEMPTION_PENALTY_DECAY;
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

	function getSupplyChangeDivisor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_DIVISOR});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    // bonds logic
    function getBondRedeemableTWAPCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({ value: BOND_REDEEMABLE_TWAP_CAP });
    }

    function getBondRedeemableTWAPFloor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({ value: BOND_REDEEMABLE_TWAP_FLOOR });
    }

    function getBondPoolRatio() internal pure returns (uint256) {
        return BOND_POOL_RATIO;
    }
}
