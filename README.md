# LSP5ReceivedAssetsValidator

## Description

`LSP5ReceivedAssetsValidator` is a contract focusing on fetching and validating LSP5 received assets. This contract provides functionalities to fetch, validate, and retrieve information about assets as per the LSP5ReceivedAssets standard.

## Features

- **Fetch Assets**: Retrieve all assets associated with a contract.
- **Validate Assets**: Check if assets are at their correct indices.
- **Fetch Asset Types**: Get the type of each asset in the contract.
- **Interface Support Check**: Determine if assets support a specific interface.
- **Asset and Type Retrieval**: Fetch all assets and their respective types.

## Disclaimer

**This contract is provided "as is" and "as available,"** and is intended primarily for use by websites and interfaces to filter LSP5ReceivedAssets, thereby reducing the need for double RPC calls. It is important to note that this is experimental software. While it can be utilized by other contracts, it should be done at their own risk.

### Usage at Own Risk

Any use of this contract is at your own risk. You are solely responsible for any damage or loss that results from such use. Users are advised to conduct thorough testing and possibly consult security experts before deploying this contract in a live environment.

### Not Audited

Please be aware that this contract has not been audited by security experts. Smart contracts are a new and complex technology prone to rapid changes and updates. Users should exercise caution and are encouraged to review the contract code thoroughly to understand its logic.

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
