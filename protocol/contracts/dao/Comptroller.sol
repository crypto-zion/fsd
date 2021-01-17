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

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Setters.sol";
import "../external/Require.sol";

contract Comptroller is Setters {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Comptroller";

    function mintToAccount(address account, uint256 amount) internal {
        dollar().mint(account, amount);
        if (!bootstrappingAt(epoch())) {
            increaseDebt(amount);
        }

        balanceCheck();
    }

    function burnFromAccount(address account, uint256 amount) internal {
        dollar().transferFrom(account, address(this), amount);
        dollar().burn(amount);
        decrementTotalDebt(amount, "Comptroller: not enough outstanding debt");

        balanceCheck();
    }

    function redeemToAccount(address account, uint256 amount) internal {
        dollar().transfer(account, amount);
        decrementTotalRedeemable(amount, "Comptroller: not enough redeemable balance");

        balanceCheck();
    }

    function burnRedeemable(uint256 amount) internal {
        dollar().burn(amount);
        decrementTotalRedeemable(amount, "Comptroller: not enough redeemable balance");

        balanceCheck();
    }

    function increaseDebt(uint256 amount) internal {
        incrementTotalDebt(amount);
        resetDebt(Constants.getDebtRatioCap());

        balanceCheck();

    }

    function decreaseDebt(uint256 amount) internal {
        decrementTotalDebt(amount, "Comptroller: not enough debt");

        balanceCheck();
    }

    function increaseSupply(uint256 newSupply) internal returns (uint256, uint256, uint256, uint256) {
        (uint256 newCouponRedeemable, uint256 lessDebt, uint256 poolReward, uint256 newBondRedeemable) = (0, 0, 0, 0);

        //1. Pay out to Pool
        poolReward = newSupply.mul(Constants.getOraclePoolRatio()).div(100);
        mintToPool(poolReward);

        newSupply = newSupply > poolReward ? newSupply.sub(poolReward) : 0;
 

        //2. Pay out to Bond & Coupon
        if (totalBondRedeemable() < totalBonds() || totalRedeemable() < totalCoupons()){
            newBondRedeemable = totalBondRedeemable() < totalBonds() ? totalBonds().sub(totalBondRedeemable()) : 0;    
            newCouponRedeemable = totalRedeemable() < totalCoupons() ? totalCoupons().sub(totalRedeemable()) : 0;
            
            uint256 bondSupply = newSupply.mul(Constants.getBondPoolRatio()).div(100);                      //bondSupply = newSupply * BOND_POOL_SHARE%
            uint256 couponSupply = newSupply.mul(SafeMath.sub(100,Constants.getBondPoolRatio())).div(100);  //couponSupply = newSupply * (1-BOND_POOL_SHARE%)

            // If Bond supply is not enough, redeem coupon first, and all remaining supply go to bond
            if (bondSupply < newBondRedeemable) {
                if(newCouponRedeemable > 0){
                    newCouponRedeemable = newCouponRedeemable > couponSupply ? couponSupply : newCouponRedeemable;
                    mintToRedeemable(newCouponRedeemable);
                    newSupply = newSupply.sub(newCouponRedeemable);
                }

                if(newBondRedeemable > 0){        
                    newBondRedeemable = newBondRedeemable > newSupply ? newSupply : newBondRedeemable;          // all remaining supply to bond
                    mintToBondRedeemable(newBondRedeemable);
                    newSupply = newSupply.sub(newBondRedeemable);
                }
            // Otherwiase, redeem bond first, and all remaining supply go to coupon
            } else {
                if(newBondRedeemable > 0){        
                    newBondRedeemable = newBondRedeemable > bondSupply ? bondSupply : newBondRedeemable;        
                    mintToBondRedeemable(newBondRedeemable);
                    newSupply = newSupply.sub(newBondRedeemable);
                }

                if(newCouponRedeemable > 0){
                    newCouponRedeemable = newCouponRedeemable > newSupply ? newSupply : newCouponRedeemable;    // all remaining supply to coupon
                    mintToRedeemable(newCouponRedeemable);
                    newSupply = newSupply.sub(newCouponRedeemable);
                }
            }
        }

        //4. Payout to Dao
        if (totalBonded() == 0) {
            newSupply = 0;
        }
        if (newSupply > 0) {
            mintToDAO(newSupply);
        }

        return (newCouponRedeemable, lessDebt, newSupply.add(poolReward), newBondRedeemable);
    }

    function resetDebt(Decimal.D256 memory targetDebtRatio) internal {
        uint256 targetDebt = targetDebtRatio.mul(dollar().totalSupply()).asUint256();
        uint256 currentDebt = totalDebt();

        if (currentDebt > targetDebt) {
            uint256 lessDebt = currentDebt.sub(targetDebt);
            decreaseDebt(lessDebt);
        }
    }

    function balanceCheck() internal {
        Require.that(
            dollar().balanceOf(address(this)) >= totalBonded().add(totalStaged()).add(totalRedeemable()).add(totalBondRedeemable()),
            FILE,
            "Inconsistent balances"
        );
    }

    function mintToBonded(uint256 amount) private {
        Require.that(
            totalBonded() > 0,
            FILE,
            "Cant mint to empty pool"
        );

        uint256 poolAmount = amount.mul(Constants.getOraclePoolRatio()).div(100);
        uint256 daoAmount = amount > poolAmount ? amount.sub(poolAmount) : 0;

        mintToPool(poolAmount);
        mintToDAO(daoAmount);

        balanceCheck();
    }

    function mintToDAO(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(address(this), amount);
            incrementTotalBonded(amount);
        }
    }

    function mintToPool(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(pool(), amount);
        }
    }

    function mintToRedeemable(uint256 amount) private {
        dollar().mint(address(this), amount);
        incrementTotalRedeemable(amount);
        balanceCheck();
    }

    // bonds logic
    function mintToBondRedeemable(uint256 amount) private {
        dollar().mint(address(this), amount);
        incrementTotalBondRedeemable(amount);
        balanceCheck();
    }
}
