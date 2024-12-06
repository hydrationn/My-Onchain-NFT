// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

library NFTSVG {
    using Strings for uint256;

    struct SVGParams {
        string learn1;
        string learn2;
        string learn3;
        string study1;
        string study2;
        string study3;
        uint256 issueTimestamp;
        uint256 tokenId;
        string gradientColorStart;
        string gradientColorEnd;
        string textColorPrimary;
        string gradientX1;
        string gradientY1;
        string gradientX2;
        string gradientY2;
    }

    /// @notice SVG 생성
    /// @param params SVGParams 구조체
    /// @return svg 완성된 SVG 코드
    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
        return string(
            abi.encodePacked(
                generateDefs(params),
                generateCardHeader(params),
                generateCardContent(params),
                generateCardFooter(params),
                "</svg>"
            )
        );
    }

    /// @notice SVG의 <defs> 섹션 생성
    /// @param params SVGParams 구조체
    /// @return defs SVG <defs> 코드
    function generateDefs(SVGParams memory params) private pure returns (string memory defs) {
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500" viewBox="0 0 500 500">',
                "<defs>",
                '<linearGradient id="gradient',
                params.tokenId.toString(),
                '" x1="',
                params.gradientX1,
                '" y1="',
                params.gradientY1,
                '" x2="',
                params.gradientX2,
                '" y2="',
                params.gradientY2,
                '">',
                '<stop offset="0%" style="stop-color:',
                params.gradientColorStart,
                ';stop-opacity:1" />',
                '<stop offset="100%" style="stop-color:',
                params.gradientColorEnd,
                ';stop-opacity:1" />',
                "</linearGradient>",
                "</defs>",
                '<rect width="100%" height="100%" fill="url(#gradient',
                params.tokenId.toString(),
                ')" />'
            )
        );
    }

    /// @notice 카드 헤더(상단 텍스트) 생성
    /// @param params SVGParams 구조체
    /// @return header 헤더 텍스트 코드
    function generateCardHeader(SVGParams memory params) private pure returns (string memory header) {
        return string(
            abi.encodePacked(
                '<text x="20" y="60" font-size="35" font-weight="bold" fill="',
                params.textColorPrimary,
                '">Blockchain Class</text>',
                '<text x="20" y="90" font-size="14" fill="',
                params.textColorPrimary,
                '">Token ID: ',
                params.tokenId.toString(),
                "</text>"
            )
        );
    }

    /// @notice 카드 중간 텍스트 생성
    /// @param params SVGParams 구조체
    /// @return content 중간 텍스트 코드
    function generateCardContent(SVGParams memory params) private pure returns (string memory content) {
        return string(
            abi.encodePacked(
                '<text x="20" y="150" font-size="22" font-weight="bold" fill="',
                params.textColorPrimary,
                '">Learnings keywords</text>',
                '<text x="20" y="180" font-size="18" fill="',
                params.textColorPrimary,
                '">1. ',
                params.learn1,
                "</text>",
                '<text x="20" y="210" font-size="18" fill="',
                params.textColorPrimary,
                '">2. ',
                params.learn2,
                "</text>",
                '<text x="20" y="240" font-size="18" fill="',
                params.textColorPrimary,
                '">3. ',
                params.learn3,
                "</text>",
                '<text x="20" y="290" font-size="22" font-weight="bold" fill="',
                params.textColorPrimary,
                '">Study keywords</text>',
                '<text x="20" y="320" font-size="18" fill="',
                params.textColorPrimary,
                '">1. ',
                params.study1,
                "</text>",
                '<text x="20" y="350" font-size="18" fill="',
                params.textColorPrimary,
                '">2. ',
                params.study2,
                "</text>",
                '<text x="20" y="380" font-size="18" fill="',
                params.textColorPrimary,
                '">3. ',
                params.study3,
                "</text>"
            )
        );
    }

    /// @notice 카드 푸터(하단 텍스트) 생성
    /// @param params SVGParams 구조체
    /// @return footer 푸터 텍스트 코드
    function generateCardFooter(SVGParams memory params) private pure returns (string memory footer) {
        return string(
            abi.encodePacked(
                '<text x="20" y="470" font-size="14" fill="',
                params.textColorPrimary,
                '">IssueTimestamp: ',
                params.issueTimestamp.toString(),
                "</text>"
            )
        );
    }
}
