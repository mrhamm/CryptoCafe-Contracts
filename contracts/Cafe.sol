pragma solidity ^0.8.0;

import "./openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "./openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
  

contract Cafe is ERC1155 {

    using EnumerableSet for EnumerableSet.UintSet;
    
    
    constructor (string memory uri_, uint32 _timescale, uint256 _createCost, uint256 _feedCost, uint256 _grindReward) public ERC1155(uri_) {
        _setURI(uri_);
        timescale = _timescale;
        devAddress=msg.sender;
        createCost = _createCost;
        feedCost = _feedCost;
        grindReward = _grindReward;
    }
    /** @dev These are the constructor parameters.  Create/feed Costs are the flour required to create and feed starters.  
    Timescale represents the timescale at which starters die, feed reset time, and  grindFlour cooldown
    grindReward is the reward for grinding flour
     */
    uint256 public createCost;
    uint256 public feedCost;
    uint32 public timescale;
    uint256 public grindReward;


    /** @dev Sourdough Struct represents the living sourdough starters
    _timeOfDeath is the Unix timestamp at which the starter 'dies' and becomes unavailable for use in baking
    _childCount describes the number of times the starter has been split
    _creationTime shows when the starter was born! 
    _creator is the person who made the starter
     */

    struct Sourdough{
        uint32 _timeOfDeath;
        uint8 _childCount;
        uint32 _creationTime;
        address _creator;
        bool _beingAutoFed;
        uint32 _splitCooldown;
        }

/** @dev Recipe struct represents baked items.  
_name is the name..must be unique
_flourRequired is burned when baking the recipe
_ages is an array of the ages of the required starter ingredients*/
    struct Recipe{
        string _name;
        uint256 _flourRequired;
        uint32[] _ages;
        address _creator;
        uint256 _timesBaked;
        uint256 _numberEaten;
        uint32 _score;
        
    }
/** @dev flourId denotes the id of the fungible FLOUR token
dividerIndex separates fully-non-fungible starter ingredients and semi-fungible baked goods
flourId is the index of the fungible flour asset
grindCooldown determine whether or not an address can grind flour
 */
    address public devAddress = address(this);
    uint256 flourId = 0;
    uint256 dividerIndex = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    mapping (uint256 => Sourdough) Sourdoughs;
    mapping(address => uint32) grindCooldown;

    mapping(uint256 => Recipe) BakedGoods;
    mapping(address =>  EnumerableSet.UintSet) private _ownerRecipes;
    mapping(address => uint256) totalScore;
    mapping(address => bool) isAutoFeeding;

/** @dev highscores here */
    uint32[11] public starterHighScoreAges;
    uint256[11] public starterHighScore;
    uint256[11] public recipeHighScore;
    address[11] public playerHighScore;

   
   
   
/** @dev total stats
 */ 
    uint256 public flourSupply = 0;
    uint256 public startersCreated = 0;
    uint256 public itemsBaked = 0;
    uint256 public recipesPublished = 0;

/** @dev Credits the user FLOUR every 24 hours if submitted
 */
    function grindFlour() public {
       
        require(grindCooldown[msg.sender]<block.timestamp,"You did this already today!");
        _mint(msg.sender,flourId, grindReward, "");
        flourSupply += grindReward;
        grindCooldown[msg.sender] = uint32(block.timestamp + timescale);
    }

/** @dev Internally used to get rid of flour tokens */
    function _burnFlour(address account, uint256 amount) internal {
        require(balanceOf(msg.sender,flourId)>=amount);
        _burn(account,flourId,amount);
        flourSupply -= amount;
    }

/** @dev Makes a new nonfungible starter with age attributes by burning 50 FLOUR */
    function createStarter() public returns (bool) {
        _burnFlour(msg.sender,  createCost);  
        uint256 tokenId = startersCreated +1; 
        _mint(msg.sender, 0+tokenId, 1,"");
        Sourdough memory sourdough = Sourdough(uint32(block.timestamp + timescale),0,uint32(block.timestamp),msg.sender,false,uint32(block.timestamp));
        
        startersCreated+=1;
        Sourdoughs[tokenId] = sourdough;
        return true;
    
    }
/** @dev Burns 50 FLOUR and resets the time of death for your token*/
    function feedStarter(uint256 tokenId) public returns (bool) {
        require(balanceOf(msg.sender,tokenId) == 1 , "This Id number is not associated with one of your starters, please try with a valid id.");
        require(Sourdoughs[tokenId]._timeOfDeath >= block.timestamp, "Your starter is dead!  You should have fed it sooner :( .");
        _burnFlour(msg.sender, feedCost);
        Sourdoughs[tokenId]._timeOfDeath = uint32(block.timestamp + timescale);
        if(Sourdoughs[tokenId]._beingAutoFed){
            Sourdoughs[tokenId]._beingAutoFed==false;
        }
        _updateStarterScore(tokenId);

        return true;
    }

/** @dev Feeds and duplicates your starter, returning another with identical age - costs 100 FLOUR */
    function splitStarter(uint256 tokenId) public returns (bool) { 
        require(balanceOf(msg.sender,tokenId)==1, "This Id number is not associated with one of your starters, please try with a valid id.");
        require(Sourdoughs[tokenId]._splitCooldown <= block.timestamp,"You have split the starter already today! Wait til' tomorrow");
        feedStarter(tokenId);
        feedStarter(tokenId);
        createStarter();
        Sourdoughs[startersCreated]._creationTime = Sourdoughs[tokenId]._creationTime;
        Sourdoughs[startersCreated]._splitCooldown = uint32(block.timestamp + 1 days);
        Sourdoughs[tokenId]._childCount+=1;
        Sourdoughs[tokenId]._splitCooldown =uint32(block.timestamp + 1 days);
        return true;

    }
/** @dev Internal. Takes a recipe struct and a batch of ingredients by id number.  Burns the ingredients and FLOUR required, then mints a semi-fungible item to the owner
with the Id of the recipe */
    function _bakeRecipe(Recipe memory recipe, uint256[] memory starterBatch) internal returns (bool) {
        require(balanceOf(msg.sender, flourId)>= recipe._flourRequired,"You don't have enough FLOUR to bake that!!");
        uint length = recipe._ages.length;
        uint[] memory amounts = new uint[](length);
        require(recipe._ages.length == starterBatch.length,"You haven't added the right number of starters to the batch!");
        for(uint i=0;i<recipe._ages.length;i++){
            uint32 starterAge = uint32(block.timestamp-Sourdoughs[starterBatch[i]]._creationTime);
            require(starterAge > recipe._ages[i], "Your starters are not old enough, please use the starters required by this recipe");  
            require(Sourdoughs[starterBatch[i]]._timeOfDeath >= block.timestamp, "Your starters are not all alive, you must use a living ingredient!!");
            require(balanceOf(msg.sender,starterBatch[i])==1, "This Id number is not associated with one of your starters, please try with a valid id.");
            amounts[i] = 1;
        }
        _burnBatch(msg.sender, starterBatch, amounts); 
        _burnFlour(msg.sender,recipe._flourRequired);
        return true;
    }
/** @dev Bakes and publishes a recipe that does not yet exist */
    function publishNewRecipe(string memory name, uint256 flourRequired, uint32[] memory ages, uint256[] memory starterBatch) public returns (uint256) {
        require(ages.length <=10, "You can only have up to 10 ingredients!");
        Recipe memory recipe = Recipe(name,flourRequired, ages,msg.sender,0,0,0);
        _bakeRecipe(recipe,starterBatch);

        uint32[] memory ages = recipe._ages;
        uint32 total;
        for(uint i=0;i<ages.length;i++){
            total+=ages[i];
        }
        recipe._score = total;

        recipe._timesBaked+=1;
        itemsBaked+=1;
        recipesPublished+=1;
        uint256 recipeId = dividerIndex + recipesPublished;
        BakedGoods[recipesPublished] = recipe;
        _ownerRecipes[msg.sender].add(recipesPublished);
        _updateRecipeScore(recipesPublished);
        _mint(msg.sender,recipeId,1,"");
        return recipeId;


    }
/** @dev Takes the id of an existing recipe and a batch of ingredients.  Burns the batch and the required flour, mints an item with the recipe Id */
    function bakeExistingRecipe(uint256 recipeId, uint256[] memory starterBatch) public returns (bool) {
        Recipe memory recipe = BakedGoods[recipeId];
        _bakeRecipe(recipe,starterBatch);

        BakedGoods[recipeId]._timesBaked+=1;
        
        itemsBaked+=1;
        _updateRecipeScore(recipeId);
        _mint(msg.sender,recipeId+dividerIndex,1,"");
        return true;
    }
/** @dev Burns an item, credits the player with a score equivalent to the total age of all ingredients */
    function eatBakedGood(uint256 recipeId, uint256 amount) public returns (bool){
        require(balanceOf(msg.sender,dividerIndex + recipeId)>=amount, "You don't have that many of those to eat!");
        
        uint32 total = BakedGoods[recipeId]._score;
       
        uint256 index = recipeId + dividerIndex;
        _burn(msg.sender,index,amount);
        BakedGoods[recipeId]._numberEaten+=1;
        totalScore[msg.sender]+= uint256(total)*amount;
        _updatePlayerScore(msg.sender);

        
    }



    function autoFeed(uint feedingTimes,uint256 starterId) public returns (bool) {
        require(balanceOf(msg.sender,starterId)==1, "This Id number is not associated with one of your starters, please try with a valid id.");
        uint256 cost = feedingTimes*feedCost;
        uint256 devFee = feedingTimes*feedCost;
        _burnFlour(msg.sender, cost);
        safeTransferFrom(msg.sender,devAddress,flourId,devFee,"");
        isAutoFeeding[msg.sender]=true;
        Sourdoughs[starterId]._timeOfDeath =  uint32(block.timestamp + feedingTimes* timescale);
        Sourdoughs[starterId]._beingAutoFed = true;
        return true;
    }


    function stopAutoFeed(uint256 starterId) public returns(bool) {
        require(Sourdoughs[starterId]._beingAutoFed ==true);
        Sourdoughs[starterId]._timeOfDeath = uint32(block.timestamp + timescale);
        Sourdoughs[starterId]._beingAutoFed = false;
    }
    

    

    function _updateStarterScore(uint256 _starterId) internal {
        uint index = 0;
        bool isOnList = false;
        while(index<10){
            if(starterHighScore[index]==_starterId){
                isOnList=true;
                break;
            }
            index=index+1;
        }

        if(isOnList){
            while(index<10){
                starterHighScore[index]=starterHighScore[index+1];
                starterHighScoreAges[index]=starterHighScoreAges[index+1];
                index=index+1;
            }
        }
        index =0;
        uint32 toBeat = starterHighScoreAges[index];
        uint32 score = uint32( block.timestamp - Sourdoughs[_starterId]._creationTime );
        while(score <= toBeat){
            index=index+1;
            if(index>10){
                break;
            }else{
                toBeat = starterHighScoreAges[index];
            }
        }

        if(index<10){
            uint index2 =9;
            while(index2>=index){
                starterHighScore[index2+1] = starterHighScore[index2];
                starterHighScoreAges[index2+1]=starterHighScoreAges[index2];
                if(index2!=0){
                index2=index2-1;}
                else{
                    break;
                }
            }
            starterHighScore[index]= _starterId;
            starterHighScoreAges[index]=score;
        }
    }
    






    function _updateRecipeScore(uint256 _recipeId) internal {
        uint index = 0;
        bool isOnList = false;
        while(index<10){
            if(recipeHighScore[index]==_recipeId){
                isOnList=true;
                break;
            }
            index=index+1;
        }

        if(isOnList){
            while(index<10){
                recipeHighScore[index]=recipeHighScore[index+1];
                index=index+1;
            }
        }

        index=0;
        uint256 score = BakedGoods[_recipeId]._timesBaked;
        uint256 toBeat = BakedGoods[recipeHighScore[index]]._timesBaked;
        while(score <= toBeat){
            index=index+1;
            if(index>10){
                break;
            }else{
                toBeat = BakedGoods[recipeHighScore[index]]._timesBaked;
            }
        }

        if(index<10){
            uint index2 = 9;
            while(index2>=index){
                recipeHighScore[index2+1]=recipeHighScore[index2];
                if(index2!=0){
                index2=index2-1;}
                else{
                    break;
                }
            }
            recipeHighScore[index]=_recipeId;
        }
   }
    

    function _updatePlayerScore(address _player) internal {
        uint index = 0;
        bool isOnList = false;
        while(index<10){
            if(playerHighScore[index]==_player){
                isOnList=true;
                break;
            }
            index=index+1;
        }
        if(isOnList){
            while(index<10){
                playerHighScore[index]=playerHighScore[index+1];
                index=index+1;
            }
        }
        index=0;
        uint256 score = totalScore[_player];
        uint256 toBeat = totalScore[playerHighScore[index]];
        while(score<=toBeat){
            index=index+1;
            if(index>10){
                break;
            }else{
                toBeat = totalScore[playerHighScore[index]];
            }
        }
        if(index<10){
            uint index2 =9;
            while(index2>=index){
                playerHighScore[index2+1]=playerHighScore[index2];
                if(index2!=0){
                index2=index2-1;}
                else{
                    break;
                }
            }
            playerHighScore[index]=_player;
        }
    }







/**@dev Helper functions for the Sourdough Struct */
    function getTimeOfDeath(uint256 starterId) public view returns(uint32){
        return Sourdoughs[starterId]._timeOfDeath;
    }
    function getChildCount(uint256 starterId) public view returns(uint8){
        return Sourdoughs[starterId]._childCount;
    }
    function getCreationTime(uint256 starterId) public view returns(uint32){
        return Sourdoughs[starterId]._creationTime;
    }
    function getCreatorAddress(uint256 starterId) public view returns(address){
        return Sourdoughs[starterId]._creator;
    }
    function getIsAutoFed(uint256 starterId) public view returns(bool){
        return Sourdoughs[starterId]._beingAutoFed;
    }


/** @dev Helper functions for Recipe Struct */
    function getRecipeName(uint256 recipeId) public view returns(string memory){
        return BakedGoods[recipeId]._name;
    }

    function getRecipeScore(uint256 recipeId) public view returns(uint32){
        return BakedGoods[recipeId]._score;
    }
    function getIngredientCount(uint256 recipeId) public view returns(uint256){
        return BakedGoods[recipeId]._ages.length;
    }
     function getIngredientByIndex(uint256 recipeId, uint index) public view returns(uint32){
        return BakedGoods[recipeId]._ages[index];
    }
     function getRecipeCreator(uint256 recipeId) public view returns(address){
        return BakedGoods[recipeId]._creator;
    }
     function getFlourRequired(uint256 recipeId) public view returns(uint256){
        return BakedGoods[recipeId]._flourRequired;
    }
     function getTimesBaked(uint256 recipeId) public view returns(uint256){
        return BakedGoods[recipeId]._timesBaked;
    }
     function getNumberEaten(uint256 recipeId) public view returns(uint256){
        return BakedGoods[recipeId]._numberEaten;
    }


/** @dev Player stats and timers */
    function getGrindReset(address player) public view returns(uint32){
        return grindCooldown[player];
    }
    function getPlayerScore(address player) public view returns(uint256){
        return totalScore[player];
    }
    function isPlayerAutoFeeding(address player) public view returns(bool){
        return isAutoFeeding[player];
    }

      function recipeOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return _ownerRecipes[owner].at(index);
    }
    function getOwnerUniqueRecipes(address owner) public view returns (uint256) {
        return _ownerRecipes[owner].length();
    }
}
    
