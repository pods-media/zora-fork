// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {ERC721PresetMinterPauserAutoId} from "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import {ERC1155PresetMinterPauser} from "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import {ProtocolRewards} from "@zoralabs/protocol-rewards/src/ProtocolRewards.sol";
import {PodsCreator1155Impl} from "../../../src/nft/PodsCreator1155Impl.sol";
import {Pods1155} from "../../../src/proxies/Pods1155.sol";
import {IMinter1155} from "../../../src/interfaces/IMinter1155.sol";
import {IZoraCreator1155} from "../../../src/interfaces/IZoraCreator1155.sol";
import {IRenderer1155} from "../../../src/interfaces/IRenderer1155.sol";
import {ICreatorRoyaltiesControl} from "../../../src/interfaces/ICreatorRoyaltiesControl.sol";
import {IZoraCreator1155Factory} from "../../../src/interfaces/IZoraCreator1155Factory.sol";
import {ZoraCreatorRedeemMinterStrategy} from "../../../src/minters/redeem/ZoraCreatorRedeemMinterStrategy.sol";
import {ZoraCreatorRedeemMinterFactory} from "../../../src/minters/redeem/ZoraCreatorRedeemMinterFactory.sol";

contract ZoraCreatorRedeemMinterFactoryTest is Test {
    ProtocolRewards internal protocolRewards;
    PodsCreator1155Impl internal target;
    ZoraCreatorRedeemMinterFactory internal minterFactory;
    address payable internal tokenAdmin = payable(address(0x999));
    address payable internal factoryAdmin = payable(address(0x888));
    address internal zora;

    event RedeemMinterDeployed(address indexed creatorContract, address indexed minterContract);

    function setUp() public {
        zora = makeAddr("zora");
        bytes[] memory emptyData = new bytes[](0);
        protocolRewards = new ProtocolRewards();
        PodsCreator1155Impl targetImpl = new PodsCreator1155Impl(zora, address(0), address(protocolRewards));
        Pods1155 proxy = new Pods1155(address(targetImpl));
        target = PodsCreator1155Impl(address(proxy));
        target.initialize("test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), tokenAdmin, emptyData);

        minterFactory = new ZoraCreatorRedeemMinterFactory();
    }

    function test_contractVersion() public {
        assertEq(minterFactory.contractVersion(), "1.0.1");
    }

    function test_createMinterIfNoneExists() public {
        vm.startPrank(tokenAdmin);
        target.addPermission(0, address(minterFactory), target.PERMISSION_BIT_MINTER());
        address predictedAddress = minterFactory.predictMinterAddress(address(target));
        vm.expectEmit(false, false, false, false);
        emit RedeemMinterDeployed(address(target), predictedAddress);
        target.callSale(0, minterFactory, abi.encodeWithSelector(ZoraCreatorRedeemMinterFactory.createMinterIfNoneExists.selector));
        vm.stopPrank();

        ZoraCreatorRedeemMinterStrategy minter = ZoraCreatorRedeemMinterStrategy(predictedAddress);
        assertTrue(address(minter).code.length > 0);
    }

    function test_createMinterRequiresIZoraCreator1155Caller() public {
        ERC1155PresetMinterPauser randomToken = new ERC1155PresetMinterPauser("https://uri.com");

        vm.expectRevert(abi.encodeWithSignature("CallerNotZoraCreator1155()"));
        vm.prank(address(randomToken));
        minterFactory.createMinterIfNoneExists();
    }

    function test_getDeployedMinterForCreatorContract() public {
        vm.prank(address(target));
        minterFactory.createMinterIfNoneExists();
        address minterAddress = minterFactory.predictMinterAddress(address(target));

        assertEq(minterAddress, minterFactory.getDeployedRedeemMinterForCreatorContract(address(target)));
    }

    function test_supportsInterface() public {
        assertTrue(minterFactory.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(minterFactory.supportsInterface(type(IMinter1155).interfaceId));
        assertTrue(!minterFactory.supportsInterface(0x6467a6fc)); // old IMinter1155
    }
}
