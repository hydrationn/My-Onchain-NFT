// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./libs/NFTSVG.sol";
import "./UpbitRandomGenerator.sol";

contract OnChainSVGMetadataNFT is ERC721, UpbitRandomGenerator {
    struct Metadata {
        string name;
        string description;
        string image;
    }

    mapping(uint256 => Metadata) private _tokenMetadata;

    string[10] private _learnKeywords =
        ["Trustless", "Blockchain", "PoW", "Tokenization", "Oracle", "Hash", "NFT", "URI Scheme", "EIP", "EVM"];

    string[10] private _studyKeywords =
        ["Decentralization", "PoS", "Non-EVM", "DeFi", "Layer2", "dao", "Cross Chain", "Zero Knowledge", "Gas", "Fork"];

    uint256 private _currentTokenId = 1;

    constructor() ERC721("OnChainSVGMetadataNFT", "OCSVGNFT") {}

    function createSVGParams(uint256 tokenId, uint256[] memory randomNumber)
        internal
        view
        returns (NFTSVG.SVGParams memory)
    {
        return NFTSVG.SVGParams({
            learn1: _learnKeywords[randomNumber[0] - 1],
            learn2: _learnKeywords[randomNumber[1] - 1],
            learn3: _learnKeywords[randomNumber[2] - 1],
            study1: _studyKeywords[randomNumber[3] - 1],
            study2: _studyKeywords[randomNumber[4] - 1],
            study3: _studyKeywords[randomNumber[5] - 1],
            issueTimestamp: block.timestamp,
            tokenId: tokenId,
            gradientColorStart: "#ff7f50",
            gradientColorEnd: "#A9F5F2",
            textColorPrimary: "#ffffff",
            gradientX1: "0",
            gradientY1: "0",
            gradientX2: "1",
            gradientY2: "1"
        });
    }

    /// @notice 새로운 NFT 발행
    /// @param name NFT 이름
    /// @param description NFT 설명
    /// @return tokenId 발행된 NFT의 ID
    function mint(string memory name, string memory description, string memory salt) external returns (uint256) {
        uint256 tokenId = _currentTokenId;

        string memory image = NFTSVG.generateSVG(
            createSVGParams(tokenId, UpbitRandomGenerator.getRandomNumbers(10, 10, (block.number - tokenId), salt))
        );

        _tokenMetadata[tokenId] = Metadata({name: name, description: description, image: image});

        _mint(msg.sender, tokenId);
        _currentTokenId++;
        return tokenId;
    }

    /// @notice 토큰 URI 반환 (온체인 메타데이터 포함)
    /// @param tokenId 조회할 토큰의 ID
    /// @return tokenURI 온체인 메타데이터 URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        Metadata memory metadata = _tokenMetadata[tokenId];

        string memory json = string(
            abi.encodePacked(
                '{"name":"',
                metadata.name,
                '","description":"',
                metadata.description,
                '","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(metadata.image)),
                '","attributes":[{"trait_type":"Company","value":"AhnLab Blockchain Company"}]}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }
}
