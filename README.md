# Basic Sample Hardhat Project

```shell
npx hardhat test
```

## Set up environment

- rename `.env.example` -> `.env`
- add private key (0x123..) to `PRIVATE_KEY` field
- create api keys for desired network at https://www.alchemy.com/
- add node provider api keys (starts with `https://..`) to `PROVIDER_RINKEBY` for example for deploying on rinkeby testnet

### Generate _throwaway_ deployer address

run

```shell
npx hardhat run scripts/generateKeys.js
```

to generate a bunch of accounts with their associated private keys.
The private key can be used in the environment field `PRIVATE_KEY`.
This key can be imported to Metamask for ease-of-use.
The account needs to be funded with testnet/mainnet eth to be able to deploy.

## Deploy to testnet

```shell
npx hardhat run scripts/deploy.js --network rinkeby
```

**mainnet**:

```shell
npx hardhat run scripts/deploy.js --network mainnet
```

### Verify contract

```shell
npx hardhat verify 0x123.. --network rinkeby
```

where `0x123..` is the deployed contract address

## Whitelisting

make sure `_signerAddress` public address in the contract (.sol) matches your
account associated with `PRIVATE_KEY`.
edit `scripts/whitelist.js` (update contractAddress and whitelisted addresses)

```shell
npx hardhat run scripts/generateWhitelist.js --network rinkeby
```

copy `whitelistSignatures.js` to `src/data` in frontend
