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

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "../token/IDollar.sol";
import "../oracle/IOracle.sol";
import "../external/Decimal.sol";

contract AccountExtension1 {
    struct State {
        mapping(uint256 => uint256) bonds; // no need for allowances, bonds are not transferable
    }
}

contract EpochExtension1 {
    struct Bonds {
        uint256 outstanding;
    }

    struct State {
        Bonds bonds;
        Decimal.D256 price;
    }

}


contract StorageExtension1 {
    struct Balance {
        uint256 bondRedeemable;
        uint256 bonds;
    }

    struct State {
        Balance balance;

        mapping(address => AccountExtension1.State) accounts;
        mapping(uint256 => EpochExtension1.State) epochs;
    }
}

contract StateExtension1 {
    StorageExtension1.State _stateExtension1;
}
