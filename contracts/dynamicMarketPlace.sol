// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketPlace1 is Ownable {

    //add events bid,buy,sell

    struct Item {
        uint256 id;
        IERC721 nft;
        uint256 price;
        IERC20 tokenAddress;
    }

    struct NFTData{
        uint256 id;
        IERC721 nft;
    }

    struct collectionData{
        uint nftCount;
        // mapping (uint => NFTData) collectionItem ;
        // NFTData [] collectionItem;
        IERC721[] nftAddress;
        uint256[] nftId;
        uint256 price;
        IERC20 tokenAddress;
    }

    struct bid {
        uint256 id;
        address by;
        uint256 bid;
    }

    event buyEvent(address buyer,address seller, uint256 finalprice,IERC721 nft,uint256 NftId);
    event bidEvent(address buyer, IERC721 nft,uint256 NftId,uint256 bidAmount);
    event sellEvent(address seller, IERC721 nft,uint256 NftId,uint256 askingPrice, IERC20 tokenAddress);

    event collectionSaleEvent(address seller , IERC721[] nftAddress, uint[] nftId, uint price, IERC20 tokenAddress);
    event collectionBidEvent(address buyer , IERC721[] nftAddress, uint[] nftId, uint bidAmount);
    event collectionBuyEvent(address buyer,address seller, uint256 finalprice,IERC721[] nft,uint256[] NftId);

    uint256 public total;

    // IERC20 public token; // change to mapping of supported tokens
    mapping(IERC20 => bool) public allowedCrypto;

    mapping(uint256 => Item) public catalog;
    mapping(IERC721=> bool) public supported;
    mapping(uint256 => bid) public bids;
    mapping(uint256 => bid) public collectionbids;

    mapping (uint256 => collectionData) public collection;
    uint public collectionCount;

    constructor(IERC721 _nft,IERC20 _token){
        supported[_nft] = true;
        // token = _token;
        allowedCrypto[_token] =true;
    }

    function approveNFtType(IERC721 _nft) external onlyOwner {
        supported[_nft] = true;
    }

    //approve token
    function approveToken(IERC20 _token) external onlyOwner {
        allowedCrypto[_token] = true;
    }

    function collectionForSale(IERC721[] memory _nftAddress,uint[] memory _nftid, uint _price, IERC20 _tokenAddress ) external{
        require(_nftAddress.length==_nftid.length);
        require(_nftAddress.length>1);
        require(_price >0);
        require(allowedCrypto[_tokenAddress]==true);
        for(uint i=0; i<_nftid.length;i++){
            require(supported[_nftAddress[i]]==true);
            require(_nftAddress[i].isApprovedForAll(msg.sender, address(this))==true,"approve marketplace");
            // require(_nft.getApproved(id) == address(this),"approve marketplace");
            require(_nftAddress[i].ownerOf(_nftid[i])==msg.sender);
            collection[collectionCount].nftId.push(_nftid[i]);
            collection[collectionCount].nftAddress.push(_nftAddress[i]);
        }
        collection[collectionCount].nftCount =_nftAddress.length;
        collection[collectionCount].price =_price;
        collection[collectionCount].tokenAddress =_tokenAddress;
        collectionCount++;
        // collection[collectionCount] = _collection;
        emit collectionSaleEvent(msg.sender,_nftAddress,_nftid,_price,_tokenAddress);
        
    }

    function bidForCollection(uint256 _id,uint256 price) external {
        IERC20 token=collection[_id].tokenAddress;
        require(price > collection[_id].price,"you are low on balance");
        require(token.balanceOf(msg.sender)>=price,"bid price is too low");
        if(price > collectionbids[_id].bid){
            if(collectionbids[_id].bid !=0){
                token.transfer(collectionbids[_id].by, collectionbids[_id].bid);
            }
            require(token.transferFrom(msg.sender, address(this), price));
            collectionbids[_id] = bid(_id,msg.sender,price);
            emit collectionBidEvent(msg.sender,collection[_id].nftAddress,collection[_id].nftId,price);

        }else{
            revert("bid too low");
        }
        
    }

    function sellCollectionForBid(uint256 _id) external {
        IERC20 token=collection[_id].tokenAddress;

        for(uint256 i=0;i<collection[_id].nftCount;i++){
            require(collection[_id].nftAddress[i].ownerOf(collection[_id].nftId[i])==msg.sender,"The Nft doesnt belong to you");
        }

        for(uint256 i=0;i<collection[_id].nftCount;i++){
            collection[_id].nftAddress[i].transferFrom(msg.sender,collectionbids[_id].by,collection[_id].nftId[i]);
        }
        
        token.transfer(msg.sender, collectionbids[_id].id);

        emit collectionBuyEvent(collectionbids[_id].by,msg.sender,collectionbids[_id].bid,collection[_id].nftAddress,collection[_id].nftId);
        delete collectionbids[_id];
    }

    function placeForSale(IERC721 _nft,uint256 id,uint256 price, IERC20 _tokenId) external {
        require(supported[_nft]==true);
        require(allowedCrypto[_tokenId]==true);
        require(_nft.isApprovedForAll(msg.sender, address(this))==true,"approve marketplace");
        // require(_nft.getApproved(id) == address(this),"approve marketplace");
        require(_nft.ownerOf(id)==msg.sender);
        require(price >0);
        total++;
        catalog[total] = Item(id,_nft,price,_tokenId);
        emit sellEvent(msg.sender,_nft,id,price,_tokenId);
    }

    function bidItem(uint256 _id,uint256 price) external {
        IERC20 token=catalog[_id].tokenAddress;
        require(price > catalog[_id].price);
        require(token.balanceOf(msg.sender)>=price);
        if(price > bids[_id].bid){
            if(bids[_id].bid !=0){
                token.transfer(bids[_id].by, bids[_id].bid);
            }
            require(token.transferFrom(msg.sender, address(this), price));
            bids[_id] = bid(_id,msg.sender,price);
            emit bidEvent(msg.sender,catalog[_id].nft,catalog[_id].id,price);

        }else{
            revert("bid too low");
        }
        
    }

    function sellForBid(uint256 id) external {
        IERC20 token=catalog[id].tokenAddress;

        require(catalog[id].nft.ownerOf(catalog[id].id) == msg.sender);
        catalog[id].nft.transferFrom(msg.sender,bids[id].by,catalog[id].id);
        token.transfer(msg.sender, bids[id].bid);
        emit buyEvent(bids[id].by,msg.sender,bids[id].bid,catalog[id].nft,catalog[id].id);
        delete bids[id];
    }

    //add function to re-sell already sold nft

    fallback() external {}

    receive() external payable{}
}