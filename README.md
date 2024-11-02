# Liquidity deposit contract with width support

The idea is to implement a smart contract that deposits any amount of `token0` and `token1` in a specified 
Uniswap V3 Liquidity Pool. Also, a `width` parameter is specified, that is calculated as
`width = (upperPrice - lowerPrice) * 10000 / (lowerPrice + upperPrice)`, where `lowerPrice` and `upperPrice` are 
lower and upper price bounds for a liquidity position.

## Solution idea

There are well-known [Uniswap formulas](https://atiselsts.github.io/pdfs/uniswap-v3-liquidity-math.pdf) to calculate liquidity when 
we put `x` and `y` amounts of token0 / token1 into the pool.

(1) `x_liquidity = x * (sqrt(P) * sqrt(Ph)) / (sqrt(Ph) - sqrt(P))`

(2) `y_liquidity = y / (sqrt(P) - sqrt(Pl))`


where:

`P` – is current asset's price.

`Pl` and `Ph` – lower and upper (higher) prices of the range we are providing liquidity in.

`Pl` and `Ph` are related to each other as:

(3) `width = (Ph - Pl)*10000 / (Pl + Ph)`

For optimal deposit we should make put equal amount of liquidity (e.g. `x_liquidity` must be equal to `y_liquidity`).

**So, in order to find `Pl` and `Ph`** (then calculate `lowerTick` and `upperTick` to mint liquidity position), we must 
solve a system of equations (1), (2), (3) that is transformed into a quadratic equation with relation to `Ph` 
and then solved in a standard way.

## Implementation
Currently is in [Deposit.sol](https://github.com/TechGeorgii/test-task-uniswapv3/blob/main/src/Deposit.sol) – first version is working,
but still under development.

Tests are in [Deposit.t.sol](https://github.com/TechGeorgii/test-task-uniswapv3/blob/main/test/Deposit.t.sol).

**TODO**: more testing, test cases, including onchain testcases.

## Useful commands

To run tests on Optimism chain:
`forge test -vv -w --rpc-url RPC_URL --chain 137`

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
