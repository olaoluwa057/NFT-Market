pragma solidity ^0.8.0;


import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

contract NFtMarket  is ERC721URIStorage {
    
     address payable admin;
     enum TokenState {Sold, Available}
     enum ApprovalState {Approved, NotApproved}
     
     
   
      mapping (uint => NFT) NFTs;
      mapping(address => mapping(uint => bool)) hasBibedFor;
      mapping (address => uint) bidPrice;
      mapping (uint => mapping (address => bider)) biderToId;
      mapping (uint => uint) BidAmountToTokenId;
      mapping (address => Vendor) Vendors;
     
      
      
    
    
    constructor () ERC721('OlaNFT', 'OLANFT')  {
        admin = payable( msg.sender); 
    }
    
    
    modifier onlyAdmin () {
        require (msg.sender == admin, 'only admin can call this function');
        
        _;
    }
    
    uint TokenID = 0;
   uint bidcount = 0;
    uint BidAmount = 0;
    
    uint HighestBiderPrice = 0;
    address public HighestBiderAddress ;
    
    address [] payementReciver;
    uint [] paymentPortions; 
    
   
    
    struct Vendor{
    uint nftCount; 
    uint withdrawnBalance;
    uint userWeiBalance;
    uint soldPrice;
 
    }
    
    struct NFT {
         uint256 price;
        uint256 _tokenId;
        string  tokenURL;
        TokenState tokenState;
        uint bidcount;
        uint soldPrice;
        address ownerAddress;
        
         bool doesExist;
         bool paidFor;
         ApprovalState approvalState;
         
        
    }
    
    struct bider {
        address biderAdress;
        uint bidPrice;
        bool canPay;
    }
    

    
    NFT[] allNFT;
  
  
  
  
   ///////////***********view functions****////////////
    
    function checkAdminAddress () public view returns (address) {//
        return(admin);
    }
    
    
      function  checkOwnerAddress (uint _id)  public onlyAdmin view returns(address){ ///view functions 
       address ownerAddress = NFTs[_id].ownerAddress;
       return(ownerAddress);
    }
    
    
    
       function contractEtherBalance() public onlyAdmin view returns(uint256){
        return address(this).balance;
    }
    
    function nftOwner (uint _tokenId) public view returns(address) {
        
        address owner = ownerOf(_tokenId);
        
        return(owner);
    }
    
    function viewTokenUrl (uint _tokenId) public view returns (string memory) {
        
       string memory TokenUrl = tokenURI(_tokenId);
       
       return(TokenUrl);
        
        
    }
    
    
    ///////////***********send functions****////////////
    
    

    
    function placeForSell (uint _startingPrice, string memory _tokenUrl) public returns ( uint, uint) {// function to mint NFT
        require (_startingPrice > 0, 'you cannot set price to zero');
        TokenID = TokenID + 1;
       _mint(msg.sender, TokenID);
        _setTokenURI(TokenID, _tokenUrl);
    uint VendorNumberofNFT =  Vendors[msg.sender].nftCount++; 
       NFT memory allNFTs = NFT(_startingPrice, TokenID,_tokenUrl, TokenState.Available, 0,0,msg.sender,true,false, ApprovalState.NotApproved);
         NFTs[TokenID] = NFT(_startingPrice, TokenID,_tokenUrl, TokenState.Available, 0,0,msg.sender,true, false, ApprovalState.NotApproved) ;
         allNFT.push(allNFTs);
            return (TokenID, VendorNumberofNFT);
        
    }
    
    function bid (uint _tokenId, uint _bidAmount) public returns (string memory, uint, uint) { //function to bid for NFT
        require(NFTs[_tokenId].doesExist == true, 'Token id does not exist');
        require(msg.sender != NFTs[_tokenId].ownerAddress, 'NFTs owner cannot bid for NFT');
        require (hasBibedFor[msg.sender][_tokenId] == false, 'you cannot bid for an Nft twice');
        require (BidAmountToTokenId[_tokenId] < _bidAmount, 'this Nft already has an higher or equal bider');
        require (NFTs[_tokenId].price <= _bidAmount, 'You cannot bid below the startingPrice');
       uint TotalBid = NFTs[_tokenId].bidcount++;
        bidPrice[msg.sender] = _bidAmount; 
        uint bidAmount = bidPrice[msg.sender];
        hasBibedFor[msg.sender][_tokenId]= true;
        biderToId[_tokenId][msg.sender]= bider(msg.sender,_bidAmount, true);
        if (BidAmountToTokenId[_tokenId] < _bidAmount ){  // this function ,a
            BidAmountToTokenId[_tokenId] = _bidAmount; 
        }
        return('You have sucessfully bided for this NFT', bidAmount, TotalBid);
        
    }
    
    function CheckhighestBidDEtails (uint _id) public onlyAdmin returns(uint, address) { // function that calls highest bidder address
    require(NFTs[_id].doesExist == true, 'Token id does not exist');
    

        HighestBiderPrice = BidAmountToTokenId[_id];
        
        if ( biderToId[_id][msg.sender].bidPrice >= HighestBiderPrice){
            HighestBiderAddress = biderToId[_id][msg.sender].biderAdress;
            
        }
        
       return(HighestBiderPrice,HighestBiderAddress);
        
    }
    
    function approve (uint _tokenId) public {// function for nFT owner to approve token sale.
    require(msg.sender == NFTs[_tokenId].ownerAddress, 'only nft owner can call this function');
        approve(HighestBiderAddress, _tokenId);
        
        NFTs[_tokenId].approvalState = ApprovalState.Approved;
    }
    
    
    function PayForNFT (uint _tokenId, uint _amount) public payable  {//function for higest bider to pay for NFT
        require(NFTs[_tokenId].doesExist == true, 'Token id does not exist');
       require(msg.value == _amount, "DepositEther:Amount sent does not equal amount entered");
        require (msg.sender == HighestBiderAddress, 'only highest bidder can pay' );
        require (msg.value == HighestBiderPrice, 'amount is less than higest bid price');
        require(NFTs[_tokenId].approvalState == ApprovalState.Approved, 'vendor has not approve you to pay for this token');
        address nftOwner = ownerOf(_tokenId);
        address buyer = msg.sender;
        
        NFTs[_tokenId].soldPrice = _amount;
       safeTransferFrom(nftOwner, buyer, _tokenId);
  
  NFTs[_tokenId].tokenState = TokenState.Sold;
       
    }
    
function payVendor (uint _tokenId) public payable { // fuction to pay vendor and admin value of sold nft
    require(msg.sender == admin, 'Only admin can call this function');
    require (NFTs[_tokenId].paidFor == false, 'Payments for this NFT had been disbursted');
    
     uint   soldPrice =  NFTs[_tokenId].soldPrice ;
     address ownerAddress = NFTs[_tokenId].ownerAddress;
     uint adminPortion = soldPrice * 10/100 ;
     uint nftOwnerPortion = soldPrice * 90/100;
     
     
   
        for(uint256 i = 0; i<payementReciver.length; i++){ // loops through array to pay both vendor and admin with a sign transaction
            payementReciver = [ownerAddress, admin];
            paymentPortions = [nftOwnerPortion, adminPortion];
            
            payable(payementReciver[i]).transfer(paymentPortions[i]);
        }
        
        NFTs[_tokenId].paidFor == true;
        
    }
     
    
}
