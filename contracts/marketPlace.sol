pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract marketPlace is Ownable {

    //add events bid,buy,sell

    struct Item {
        uint256 id;
        IERC721 nft;
        uint256 price;
    }

    struct bid {
        uint256 id;
        address by;
        uint256 bid;
    }

    uint256 public total;

    IERC20 public token; // change to mapping of supported tokens

    mapping(uint256 => Item) public catalog;
    mapping(IERC721=> bool) public supported;
    mapping(uint256 => bid) public bids;

    constructor(IERC721 _nft,IERC20 _token){
        supported[_nft] = true;
        token = _token;
    }

    function approveNFtType(IERC721 _nft) external onlyOwner {
        supported[_nft] = true;
    }

    //approve token

    function placeForSale(IERC721 _nft,uint256 id,uint256 price) external {
        require(supported[_nft]==true);
        require(_nft.getApproved(id) == address(this),"approve marketplace");
        require(_nft.ownerOf(id)==msg.sender);
        require(price >0);
        total++;
        catalog[total] = Item(id,_nft,price);
    }

    function bidItem(uint256 _id,uint256 price) external {
        require(price > catalog[_id].price);
        require(token.balanceOf(msg.sender)>=price);
        if(price > bids[_id].bid){
            if(bids[_id].bid !=0){
                token.transfer(bids[_id].by, bids[_id].bid);
            }
            require(token.transferFrom(msg.sender, address(this), price));
            bids[_id] = bid(_id,msg.sender,price);

        }else{
            revert("bid too low");
        }
    }

    function sellForBid(uint256 id) external {
        require(catalog[id].nft.ownerOf(catalog[id].id) == msg.sender);
        catalog[id].nft.transferFrom(msg.sender,bids[id].by,catalog[id].id);
        token.transfer(msg.sender, bids[id].bid);
        delete bids[id];
        delete catalog[id];
    }

    //add function to re-sell already sold nft

    fallback() external {}

    receive() external payable{}
}