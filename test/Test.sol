// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {ERC1155 as ERC1155V4} from "@oz4/token/ERC1155/ERC1155.sol";
import {ERC1155 as ERC1155V5} from "@oz5/token/ERC1155/ERC1155.sol";

// unchanged between versions
import {IERC1155Receiver} from "@oz4/token/ERC1155/IERC1155Receiver.sol";

uint256 constant TOKEN_ID = 1;

contract V4 is ERC1155V4 {
    constructor() ERC1155V4("") {}
    function mint(address to) external {
        _mint(to, TOKEN_ID, 1, "");
    }
}

contract V5 is ERC1155V5 {
    constructor() ERC1155V5("") {}
    function mint(address to) external {
        _mint(to, TOKEN_ID, 1, "");
    }
}

contract PoCTest is Test, IERC1155Receiver {
    V4 v4;
    V5 v5;

    bytes singleData;
    bytes batchData;

    address user = makeAddr("user");

    function setUp() external {
        v4 = new V4();
        v5 = new V5();
    }

    function supportsInterface(bytes4) external pure returns (bool) {
        return true;
    }

    function test_v4() external {
        v4.mint(user);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        bytes[] memory datas = new bytes[](1);
        ids[0] = TOKEN_ID;
        amounts[0] = 1;
        datas[0] = hex"beef";
        vm.prank(user);
        v4.safeBatchTransferFrom(
            user,
            address(this),
            ids,
            amounts,
            abi.encode(datas)
        );
        this.assertTransfer();
    }

    function test_v5() external {
        v5.mint(user);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        bytes[] memory datas = new bytes[](1);
        ids[0] = TOKEN_ID;
        amounts[0] = 1;
        datas[0] = hex"beef";
        vm.prank(user);
        v5.safeBatchTransferFrom(
            user,
            address(this),
            ids,
            amounts,
            abi.encode(datas)
        );
        vm.expectRevert();
        this.assertTransfer();
    }

    function assertTransfer() external view {
        // we transferred a batch of 1
        // we should of received onERC1155BatchReceived
        // so there should be no single data
        assertEq(singleData.length, 0, "single");
        // and only batch data
        assertGt(batchData.length, 0, "batch");
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata data
    ) external returns (bytes4) {
        singleData = data;
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata data
    ) external returns (bytes4) {
        batchData = data;
        return this.onERC1155BatchReceived.selector;
    }
}
