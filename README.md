# StakingApp — Fixed-Amount Token Staking with Time-Locked Rewards

A Foundry project implementing a simplified staking protocol: users stake a **fixed amount** of an ERC20 token and become eligible for an ETH reward once a configurable **time lock** has elapsed. Built as part of the Blockchain Accelerator program, with a focus on access control, the CEI (Checks-Effects-Interactions) pattern, and time-based testing.

## How it works

- `StakingToken.sol` — a minimal ERC20 (OpenZeppelin-based) with a public `mint()` so any address can get test tokens.
- `StakingApp.sol` — the staking contract:
  - `depositTokens(amount)` — stakes exactly `fixedStakingAmount` tokens (one active stake per address at a time).
  - `withdrawTokens()` — withdraws the full staked balance.
  - `claimRewards()` — pays out `rewardPerPeriod` in ETH once `stakingPeriod` has elapsed since deposit, then resets the clock.
  - `changeStakingPeriod(newPeriod)` — `onlyOwner`, lets the admin adjust the lock duration.
  - `receive()` — `onlyOwner`, the contract's only funding path for ETH rewards.

## Design decisions & security notes

- **CEI pattern on state-changing paths**: in both `withdrawTokens()` and `claimRewards()`, internal state (`userBalance`, `elapsePeriod`) is updated **before** any external call/transfer, reducing reentrancy surface even where it isn't strictly required by this contract's logic.
- **Access control**: only the `owner` (set via OpenZeppelin's `Ownable`, OZ v5.x explicit `initialOwner` constructor) can change the staking period or fund the contract with ETH.
- **Funding model is a known limitation by design**: reward payouts depend on the owner manually sending ETH to the contract. If the contract isn't funded, `claimRewards()` reverts with `"Transfer failed"` — this is covered explicitly by `testShouldRevertIfNoEther`, rather than left as an untested edge case.
- **Raw ERC20 calls (`transfer`/`transferFrom`) instead of `SafeERC20`**: unlike the CryptoBank project, this version calls the token interface directly. Since `StakingToken` is a standard OpenZeppelin ERC20 that reverts on failure, this is safe here — but it's worth flagging that with a non-standard ERC20 (one that returns `false` instead of reverting), an unchecked `transfer`/`transferFrom` could silently fail. `SafeERC20` is the safer default in production code and is the next planned improvement.

## Tests

13 tests across `test/StakingAppTest.t.sol` and `test/StakingTokenTest.t.sol`, covering:
- Correct deployment of both contracts
- Access control on `changeStakingPeriod` (revert for non-owner, success for owner)
- Receiving ETH via `receive()`
- Deposit validation (wrong amount, double-deposit protection)
- Withdraw flow (zero balance, full balance)
- Reward claim flow: not staking, time lock not elapsed, contract underfunded, and the full happy path using `vm.warp` to simulate time passing

```shell
forge build
forge test -vvv
```

## Stack

- Foundry (Forge / Cast / Anvil)
- OpenZeppelin Contracts v5.x (`ERC20`, `Ownable`)