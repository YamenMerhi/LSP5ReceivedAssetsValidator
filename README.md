# LSP5ReceivedAssetsValidator

## Description

`LSP5ReceivedAssetsValidator` is a contract focusing on managing and validating LSP5 received assets. This contract provides functionalities to interact with, validate, and retrieve information about assets as per the LSP5 standard.

## Features

- **Fetch Assets**: Retrieve all assets associated with a contract.
- **Validate Assets**: Check if assets are at their correct indices.
- **Fetch Asset Types**: Get the type of each asset in the contract.
- **Interface Support Check**: Determine if assets support a specific interface.
- **Asset and Type Retrieval**: Fetch all assets and their respective types.

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
