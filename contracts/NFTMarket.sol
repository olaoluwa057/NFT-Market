pragma solidity ^0.8.0;


import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

contract NFtMarket  is ERC721URIStorage {
    
    address payable admin;
     enum TokenState {Sold, Available}
     
   
    mapping (uint => NFT) NFTs;
      mapping(address => mapping(uint => bool)) hasBibedFor;
      mapping (address => uint) bidPrice;
      mapping (uint => mapping (address => bider)) biderToId;
      mapping (uint => uint) BidAmountToTokenId;
      mapping (address => Vendor) Vendors;
      
      
    
    
    constructor () ERC721('OlaNFT', 'OLANFT')  {
        admin = payable( msg.sender); 
    }
    
    uint TokenID = 0;
   uint bidcount = 0;
    uint BidAmount = 0;
    
    uint HighestBiderPrice = 0;
    address public HighestBiderAddress ;
    
   
    
    struct Vendor{
    uint nftCount; 
    uint withdrawnBalance;
    uint userWeiBalance;
 
    }
    
    struct NFT {
         uint256 price;
        uint256 _tokenId;
        string  tokenURL;
        TokenState tokenState;
        uint bidcount;
         bool doesExist;
        
    }
    
    struct bider {
        address biderAdress;
        uint bidPrice;
        bool canPay;
    }
    

    
    NFT[] allNFT;
  
    
    
    
    function placeForSell (uint _startingPrice, string memory _tokenUrl) public returns ( uint, uint) {
        require (_startingPrice > 0, 'you cannot set price to zero');
        TokenID = TokenID + 1;
       _mint(msg.sender, TokenID);
      _setTokenURI(TokenID, _tokenUrl);
    uint VendorNumberofNFT =  Vendors[msg.sender].nftCount++; 
       NFT memory allNFTs = NFT(_startingPrice, TokenID,_tokenUrl, TokenState.Available, 0,true);
         NFTs[TokenID] = NFT(_startingPrice, TokenID,_tokenUrl, TokenState.Available,0,true);
         allNFT.push(allNFTs);
            return (TokenID, VendorNumberofNFT);
        
    }
    
    function bid (uint _tokenId, uint _bidAmount) public returns (string memory, uint, uint) {
        require(NFTs[_tokenId].doesExist == true, 'Token id does not exist');
        require (hasBibedFor[msg.sender][_tokenId] == false, 'you cannot bid for an Nft twice');
        require (BidAmountToTokenId[_tokenId] < _bidAmount, 'this Nft already has an higher or equal bider');
        require (NFTs[_tokenId].price <= _bidAmount, 'You cannot bid below the startingPrice');
       uint TotalBid = NFTs[_tokenId].bidcount++;
      
        bidPrice[msg.sender] = _bidAmount;
        uint bidAmount = bidPrice[msg.sender];
        hasBibedFor[msg.sender][_tokenId]= true;
        biderToId[_tokenId][msg.sender]= bider(msg.sender,_bidAmount, true);
        if (BidAmountToTokenId[_tokenId] < _bidAmount ){
            BidAmountToTokenId[_tokenId] = _bidAmount;
        }
        return('You have sucessfully bided for this NFT', bidAmount, TotalBid);
        
    }
    
    function CheckhighestBidDEtails (uint _id) public  returns(uint, address) {
    require(NFTs[_id].doesExist == true, 'Token id does not exist');
        HighestBiderPrice = BidAmountToTokenId[_id];
        
        if ( biderToId[_id][msg.sender].bidPrice >= HighestBiderPrice){
            HighestBiderAddress = biderToId[_id][msg.sender].biderAdress;
        }
       return(HighestBiderPrice,HighestBiderAddress);
        
    }
    
    
    function PayForNFT (uint _tokenId, uint _amount) public payable returns(uint) {
        require(NFTs[_tokenId].doesExist == true, 'Token id does not exist');
       require(msg.value == _amount, "DepositEther:Amount sent does not equal amount entered");
        require (msg.sender == HighestBiderAddress, 'only highest bidder can pay' );
        require (msg.value == HighestBiderPrice, 'amount is less than higest bid price');
        Vendors[msg.sender].userWeiBalance += _amount;
        address nftOwner = ownerOf(_tokenId);
        address buyer = msg.sender;
        safeTransferFrom(nftOwner, buyer, _tokenId);
         payable(address(this)).transfer(msg.value); 
          uint VendorNumberofNFT =  Vendors[msg.sender].nftCount--; 
        return(VendorNumberofNFT);
    }
    
       function contractEtherBalance() public view returns(uint256){
        return address(this).balance;
    }

    
}