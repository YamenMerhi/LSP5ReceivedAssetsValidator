// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";
import "@lukso/lsp-smart-contracts/contracts/LSP5ReceivedAssets/LSP5Constants.sol";

import "@lukso/lsp-smart-contracts/contracts/LSP2ERC725YJSONSchema/LSP2Utils.sol";

/// @title LSP5 Received Assets Validator Library
/// @notice This library provides functionalities to interact with, validate,
///         and retrieve information about assets as per the LSP5 standard. It is designed
///         primarily for use with contracts that adhere to the LSP5 standard, enabling
///         efficient handling and validation of received assets.
/// @dev This library assumes that the contract on which it operates supports the IERC725Y
///      interface, especially the `getData(bytes32) -> bytes` function. This assumption
///      is critical for the correct operation of the library's functions, as they rely
///      on fetching data from the contract using the `getData` method defined in IERC725Y.
///      Ensure that any contract using this library conforms to the expected interface
///      to avoid unexpected behaviors or errors.
library LSP5ReceivedAssetsValidator {
    /// @notice Executes a batch of calls on the contract itself using `delegatecall`.
    /// @dev This function allows batch processing of multiple calls in a single transaction.
    ///       It uses `delegatecall` to execute each call, which means that each call has access
    ///       to the contract's state and can alter it. If any call fails, it attempts to
    ///       bubble up the revert reason, if any, otherwise, it reverts with a generic error message.
    /// @param data An array of calldata bytes (contract functions) to be executed in the batch.
    /// @return results An array of bytes representing the results of each executed call.
    ///         If a call reverts, the transaction is reverted and no results are returned.
    function batchCalls(
        bytes[] calldata data
    ) public returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i; i < data.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

            if (!success) {
                // Look for revert reason and bubble it up if present
                if (result.length != 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
                    // solhint-disable no-inline-assembly
                    /// @solidity memory-safe-assembly
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert("LSP5ReceivedAssetsValidator: batchCalls reverted");
                }
            }

            results[i] = result;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Fetches the total count of assets associated with the given contract.
    /// @param _contract The address of the contract.
    /// @return The total number of assets.
    function fetchAssetsCount(address _contract) public view returns (uint128) {
        return
            uint128(
                bytes16(
                    IERC725Y(_contract).getData(_LSP5_RECEIVED_ASSETS_ARRAY_KEY)
                )
            );
    }

    /// @notice Fetches all assets associated with the given contract.
    /// @param _contract The address of the contract.
    /// @return An array of asset addresses.
    function fetchAssets(
        address _contract
    ) public view returns (address[] memory) {
        uint128 assetsCount = uint128(
            bytes16(
                IERC725Y(_contract).getData(_LSP5_RECEIVED_ASSETS_ARRAY_KEY)
            )
        );
        address[] memory assets = new address[](assetsCount);

        for (uint128 i = 0; i < assetsCount; i++) {
            bytes32 key = LSP2Utils.generateArrayElementKeyAtIndex(
                _LSP5_RECEIVED_ASSETS_ARRAY_KEY,
                i
            );

            address asset = address(bytes20(IERC725Y(_contract).getData(key)));
            assets[i] = asset;
        }
        return assets;
    }

    /// @notice Fetches the count of assets that are validated (i.e., have a balance greater than 0) associated with the given contract.
    /// @param _contract The address of the contract.
    /// @return The count of validated asset addresses.
    function fetchValidatedAssetsCount(
        address _contract
    ) public view returns (uint128) {
        uint128 assetsCount = uint128(
            bytes16(
                IERC725Y(_contract).getData(_LSP5_RECEIVED_ASSETS_ARRAY_KEY)
            )
        );

        uint128 validatedCount = 0;

        for (uint128 i = 0; i < assetsCount; i++) {
            bytes32 key = LSP2Utils.generateArrayElementKeyAtIndex(
                _LSP5_RECEIVED_ASSETS_ARRAY_KEY,
                i
            );

            address asset = address(bytes20(IERC725Y(_contract).getData(key)));

            if (ILSP7DigitalAsset(asset).balanceOf(_contract) > 0) {
                validatedCount++;
            }
        }

        return validatedCount;
    }

    /// @notice Fetches the count of assets that are validated (i.e., have a balance greater than 0)
    ///         associated with the given contract, with error handling for the balanceOf call.
    /// @dev This function iterates over all assets and counts the number of assets with a balance
    ///      greater than 0. If the balanceOf call fails, the asset is not counted.
    /// @param _contract The address of the contract.
    /// @return validatedCount The count of validated asset addresses.
    function fetchValidatedAssetsCountWithHandling(
        address _contract
    ) public view returns (uint128 validatedCount) {
        uint128 assetsCount = uint128(
            bytes16(
                IERC725Y(_contract).getData(_LSP5_RECEIVED_ASSETS_ARRAY_KEY)
            )
        );

        validatedCount = 0;

        for (uint128 i = 0; i < assetsCount; i++) {
            bytes32 key = LSP2Utils.generateArrayElementKeyAtIndex(
                _LSP5_RECEIVED_ASSETS_ARRAY_KEY,
                i
            );

            address asset = address(bytes20(IERC725Y(_contract).getData(key)));

            if (asset.code.length != 0) {
                try ILSP7DigitalAsset(asset).balanceOf(_contract) returns (
                    uint256 balance
                ) {
                    if (balance > 0) {
                        validatedCount++;
                    }
                } catch {
                    // Ignore the asset if balanceOf call fails
                }
            }
        }
    }

    /// @notice Fetches assets that are validated (i.e., have a balance greater than 0).
    /// @param _contract The address of the contract.
    /// @return An array of validated asset addresses.
    function fetchValidatedAssets(
        address _contract
    ) public view returns (address[] memory) {
        uint128 assetsCount = uint128(
            bytes16(
                IERC725Y(_contract).getData(_LSP5_RECEIVED_ASSETS_ARRAY_KEY)
            )
        );
        address[] memory validatedAssets = new address[](assetsCount);
        uint128 validatedCount = 0;

        for (uint128 i = 0; i < assetsCount; i++) {
            bytes32 key = LSP2Utils.generateArrayElementKeyAtIndex(
                _LSP5_RECEIVED_ASSETS_ARRAY_KEY,
                i
            );

            address asset = address(bytes20(IERC725Y(_contract).getData(key)));

            if (ILSP7DigitalAsset(asset).balanceOf(_contract) > 0) {
                validatedAssets[validatedCount++] = asset;
            }
        }

        // Resize the array to fit the actual number of validated assets
        address[] memory trimmedAssetsValidated = new address[](validatedCount);
        for (uint128 k = 0; k < validatedCount; k++) {
            trimmedAssetsValidated[k] = validatedAssets[k];
        }

        return trimmedAssetsValidated;
    }

    /// @notice Fetches assets that are validated (i.e., have a balance greater than 0).
    /// @param _contract The address of the contract.
    /// @return An array of validated asset addresses.
    function fetchValidatedAssetsWithHandling(
        address _contract
    ) public view returns (address[] memory) {
        uint128 assetsCount = uint128(
            bytes16(
                IERC725Y(_contract).getData(_LSP5_RECEIVED_ASSETS_ARRAY_KEY)
            )
        );
        address[] memory validatedAssets = new address[](assetsCount);
        uint128 validatedCount = 0;

        for (uint128 i = 0; i < assetsCount; i++) {
            bytes32 key = LSP2Utils.generateArrayElementKeyAtIndex(
                _LSP5_RECEIVED_ASSETS_ARRAY_KEY,
                i
            );

            address asset = address(bytes20(IERC725Y(_contract).getData(key)));

            if (asset.code.length != 0) {
                try ILSP7DigitalAsset(asset).balanceOf(_contract) returns (
                    uint256 balance
                ) {
                    if (balance > 0) {
                        validatedAssets[validatedCount++] = asset;
                    }
                } catch {
                    // Skipping this asset
                }
            }
        }

        // Resize the array to fit the actual number of validated assets
        address[] memory trimmedAssetsValidated = new address[](validatedCount);
        for (uint128 k = 0; k < validatedCount; k++) {
            trimmedAssetsValidated[k] = validatedAssets[k];
        }

        return trimmedAssetsValidated;
    }

    /// @notice Fetches assets along with their validation status.
    /// @param _contract The address of the contract.
    /// @return Two arrays: one for assets (addresses) and another for assets validity (boolean).
    function fetchAssetsWithValidity(
        address _contract
    ) public view returns (address[] memory, bool[] memory) {
        uint128 assetsCount = uint128(
            bytes16(
                IERC725Y(_contract).getData(_LSP5_RECEIVED_ASSETS_ARRAY_KEY)
            )
        );
        address[] memory assets = new address[](assetsCount);
        bool[] memory validity = new bool[](assetsCount);

        for (uint128 i = 0; i < assetsCount; i++) {
            bytes32 key = LSP2Utils.generateArrayElementKeyAtIndex(
                _LSP5_RECEIVED_ASSETS_ARRAY_KEY,
                i
            );

            address asset = address(bytes20(IERC725Y(_contract).getData(key)));

            assets[i] = asset;
            validity[i] = ILSP7DigitalAsset(asset).balanceOf(_contract) > 0;
        }

        return (assets, validity);
    }

    /// @notice Fetches assets along with their validation status from a contract supporting IERC725Y.
    /// @dev This function attempts to fetch the balance of each asset to determine its validity.
    ///      If the balanceOf call fails, the asset is marked as invalid.
    /// @param _contract The address of the contract.
    /// @return Two arrays: one for assets (addresses) and another for assets validity (boolean).
    ///         Validity is set to true if the balance is greater than 0, false otherwise.
    function fetchAssetsWithValidityWithHandling(
        address _contract
    ) public view returns (address[] memory, bool[] memory) {
        uint128 assetsCount = uint128(
            bytes16(
                IERC725Y(_contract).getData(_LSP5_RECEIVED_ASSETS_ARRAY_KEY)
            )
        );
        address[] memory assets = new address[](assetsCount);
        bool[] memory validity = new bool[](assetsCount);

        for (uint128 i = 0; i < assetsCount; i++) {
            bytes32 key = LSP2Utils.generateArrayElementKeyAtIndex(
                _LSP5_RECEIVED_ASSETS_ARRAY_KEY,
                i
            );

            address asset = address(bytes20(IERC725Y(_contract).getData(key)));
            assets[i] = asset;

            if (asset.code.length != 0) {
                try ILSP7DigitalAsset(asset).balanceOf(_contract) returns (
                    uint256 balance
                ) {
                    validity[i] = balance > 0;
                } catch {
                    validity[i] = false; // Mark as invalid if balanceOf call fails
                }
            } else {
                validity[i] = false; // Mark as invalid if asset is not a contract (for readability)
            }
        }

        return (assets, validity);
    }

    /// @notice Fetches an asset's address by its index.
    /// @param _contract The address of the contract.
    /// @param index The index of the asset.
    /// @return The address of the asset at the given index.
    function fetchAssetByIndex(
        address _contract,
        uint128 index
    ) public view returns (address) {
        bytes32 key = LSP2Utils.generateArrayElementKeyAtIndex(
            _LSP5_RECEIVED_ASSETS_ARRAY_KEY,
            index
        );
        return address(bytes20(IERC725Y(_contract).getData(key)));
    }

    /// @notice Fetches multiple assets' addresses by their indices.
    /// @param _contract The address of the contract.
    /// @param indices An array of indices of the assets.
    /// @return An array of addresses of the assets at the given indices.
    function fetchAssetsByIndices(
        address _contract,
        uint128[] memory indices
    ) public view returns (address[] memory) {
        address[] memory assets = new address[](indices.length);

        for (uint128 i = 0; i < indices.length; i++) {
            bytes32 key = LSP2Utils.generateArrayElementKeyAtIndex(
                _LSP5_RECEIVED_ASSETS_ARRAY_KEY,
                indices[i]
            );

            assets[i] = address(bytes20(IERC725Y(_contract).getData(key)));
        }

        return assets;
    }

    /// @notice Checks if an asset is at the correct index in the array.
    /// @param _contract The address of the contract.
    /// @param _asset The address of the asset.
    /// @return True if the asset is at the correct index, false otherwise.
    function isAssetAtCorrectIndexInArray(
        address _contract,
        address _asset
    ) public view returns (bool) {
        uint128 index = fetchAssetIndex(_contract, _asset);
        address asset = fetchAssetByIndex(_contract, index);

        return asset == _asset;
    }

    /// @notice Fetches the type and index of an asset.
    /// @param _contract The address of the contract.
    /// @param _asset The address of the asset.
    /// @return The type (bytes4) and index (uint128) of the asset.
    function fetchAssetTypeAndIndex(
        address _contract,
        address _asset
    ) public view returns (bytes4, uint128) {
        bytes memory data = IERC725Y(_contract).getData(
            LSP2Utils.generateMappingKey(
                _LSP5_RECEIVED_ASSETS_MAP_KEY_PREFIX,
                bytes20(_asset)
            )
        );

        (bytes4 assetType, uint128 assetIndex) = abi.decode(
            data,
            (bytes4, uint128)
        );

        return (assetType, assetIndex);
    }

    /// @notice Fetches the type of an asset.
    /// @param _contract The address of the contract.
    /// @param _asset The address of the asset.
    /// @return The type (bytes4) of the asset.
    function fetchAssetType(
        address _contract,
        address _asset
    ) public view returns (bytes4) {
        bytes memory data = IERC725Y(_contract).getData(
            LSP2Utils.generateMappingKey(
                _LSP5_RECEIVED_ASSETS_MAP_KEY_PREFIX,
                bytes20(_asset)
            )
        );

        (bytes4 assetType, ) = abi.decode(data, (bytes4, uint128));
        return assetType;
    }

    /// @notice Fetches the index of an asset.
    /// @param _contract The address of the contract.
    /// @param _asset The address of the asset.
    /// @return The index (uint128) of the asset.
    function fetchAssetIndex(
        address _contract,
        address _asset
    ) public view returns (uint128) {
        bytes memory data = IERC725Y(_contract).getData(
            LSP2Utils.generateMappingKey(
                _LSP5_RECEIVED_ASSETS_MAP_KEY_PREFIX,
                bytes20(_asset)
            )
        );

        (, uint128 assetIndex) = abi.decode(data, (bytes4, uint128));
        return assetIndex;
    }

    /// @notice Retrieves all assets from the LSP5 array and validates each asset's index with its map data.
    /// @param _contract The address of the contract.
    /// @return A boolean array indicating whether each asset is at its correct index according to its map data.
    function validateAssetsIndices(
        address _contract
    ) public view returns (bool[] memory) {
        address[] memory assets = fetchAssets(_contract);
        bool[] memory correctIndices = new bool[](assets.length);

        for (uint128 i = 0; i < assets.length; i++) {
            (, uint128 assetIndex) = fetchAssetTypeAndIndex(
                _contract,
                assets[i]
            );
            correctIndices[i] = (assetIndex == i);
        }

        return correctIndices;
    }

    // / @notice Fetches the types of all assets and checks if they support a specific interface.
    // / @param _contract The address of the contract.
    // / @return Two arrays: one with the addresses of the assets and another indicating whether each asset supports the specified interface.
    // function validateAssetsInterfaceIds(
    //     address _contract
    // ) public view returns (address[] memory, bool[] memory) {
    //     address[] memory assets = fetchAssets(_contract);
    //     bool[] memory supportsInterface = new bool[](assets.length);

    //     for (uint128 i = 0; i < assets.length; i++) {
    //         bytes4 assetType = fetchAssetType(_contract, assets[i]);
    //         supportsInterface[i] = IERC165(assets[i]).supportsInterface(
    //             interfaceIds[i]
    //         );
    //     }

    //     return (assets, supportsInterface);
    // }

    // fetch assets count and fetch all assets and then fetch all assets maps and decode it to its own arrat --> assets[], types[], indices[]
    // fetch asset at index, and then fetch its map information
    // fetch all validated assets and then fetch all maps and decode it to its own array --> assets[], types[], indices[]
    // fetch all validated assets and then fetch all validated maps
    // fetch an asset map and validate it support for the type
    // fetch an asset map and validate it index
    // fetch an asset map and validate the info
    // fetch assets map and validate it index
    // fetch assets map and validate the info
    // fetch several assets map and validate the infos
}
