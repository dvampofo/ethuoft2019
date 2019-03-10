pragma solidity ^0.4.25;

import "./Ownable.sol"; //function permissions
import "./ERC20.sol"; //coin
import "./SafeMath.sol";

///@author 
///@title A solidity contract for a company to add survey for Bunz
contract BunzSurvey is Ownable {

  using SafeMath for uint;

  mapping (address => string) public userResponses; //stores survey responses - this should be encrypted already
  mapping (address => string) public userHashes; //this should be encrypted already

  mapping (address => uint256) public responseState; //categorizes type of user response
    // 0 is no responose
    // 1 is responded initially
    // 2 is survey creator has disputed
    // 3 is disputed but OK
    // 4 is disputed but BAD

  mapping (address => uint256) public userReward; //perhaps this can go into a master contract so they can cash out BIG TIME - where to send user reward

  uint256 public numberOfResponses; 
  
  uint256 public surveyStatus; //survey completion

  address public bountyTokenAddress; //company's token deposit address
  ERC20 public bountyToken; //the token
  uint256 public rewardAmount; //how much given to user per survey response
  uint256 public rewardSetAside; //set aside rewards to give after survey completion (and dispute window)

  string public surveyQuestion; 
  string[] public choices; 
  uint256 public numChoices; //how many choices given by company
  uint256 public maxChoices; //maximum surveys possible on Bunz platform

  uint256 public startTimestamp; 
  uint256 public endTimestamp; 

  address bunzAddress;
  uint256 public disputeWindow=3600;//1 hours seconds

  modifier onlyWhenInSetup() { //company setting up survey
        require(surveyStatus==0);
        _;
    }
    
  modifier onlyDuringParticipation() { //while users responding to survey
        require(surveyStatus==1);
        _;
    }

  modifier onlyAfterDisputeWindow() { 
        require(surveyStatus==2 && now>=endTimestamp+disputeWindow);
        _;
  }

    modifier onlyDuringDisputeWindow() {
        require(surveyStatus==2 && now<endTimestamp+disputeWindow);
        _;
  }

    modifier onlyBunz() { //Bunz as mediator if neccessary
        require(msg.sender==bunzAddress);
        _;
  }

  // CONSTRUCTOR
  constructor(address _bountyTokenAddress,uint256 _rewardAmount, string _surveyQuestion, uint256 _maxChoices, address _bunzAddress) public {
  surveyQuestion = _surveyQuestion;
	numberOfResponses = 0;
    bountyTokenAddress = _bountyTokenAddress;
    bountyToken = ERC20(bountyTokenAddress);
    numChoices = 0;
    maxChoices=_maxChoices;
    rewardAmount=_rewardAmount;
    rewardSetAside=0;
    bunzAddress=_bunzAddress;
    surveyStatus=0;
  }

  //stage 0 funcs
  
function addChoice(string choice) public onlyOwner onlyWhenInSetup  { //for company to add choices
        require(!checkEmptyString(choice)); //choice must be given
        require(numChoices<maxChoices); //can't exceed max number of choices

        bool foundEmptySlot=false; //to account for null elements if removeChoice is uses
        
        for (uint256 i=0; i<choices.length; i=i.add(1)) {
            if( checkEmptyString(choices[i])  ){
               choices[i]=choice; //add agent in first free slot   
               foundEmptySlot=true;
               break;
            }
        }
        
        if(!foundEmptySlot){
  				choices.push(choice); 
        }
        
        numChoices=numChoices.add(1);
    }
  
function removeChoice(uint256 index) public onlyOwner onlyWhenInSetup { //company can remove choices
  delete choices[index];  
  numChoices=numChoices.sub(1);
}
function startSurvey() public onlyOwner onlyWhenInSetup {
	surveyStatus=1; //survey period 
    startTimestamp=now;
} //can deploy survey

//state 1 functions

// users participate with this function, only when its encrypted
function participate(string ancryptedAnswer, string hashedAnswer) public onlyDuringParticipation { 
    require(checkEmptyString(userResponses[msg.sender])); //participate only once
    require(numChoices!=0); 
    //require(enoughRewardLeft()); 
    
    if(enoughRewardLeft()){ //must be enough BTZ left to pay user
     	userResponses[msg.sender]=ancryptedAnswer;
        userHashes[msg.sender]=hashedAnswer;
    	responseState[msg.sender]=1; //assume good actor as a default
	    numberOfResponses=numberOfResponses.add(1);
	    userReward[msg.sender]=userReward[msg.sender].add(rewardAmount);
	    rewardSetAside=rewardSetAside.add(rewardAmount); //set aside reward to be given after survey period is over   
    }else{
        finishSurvey();
    }
    
} 

function finishSurvey() public onlyOwner onlyDuringParticipation { //company can stop survey manually 
	endTimestamp=now;
    surveyStatus=2;
}

function dispute(address badAnswerUser) public view onlyOwner onlyDuringDisputeWindow{ //company can dispute bad responses
    responseState[badAnswerUser]==2;
}

function disputeBreak(address analysedAnswerUser, bool isGood) public onlyBunz onlyDuringDisputeWindow{ //Bunz can stop dispute
    if(isGood){
        responseState[analysedAnswerUser]==3; 
    }else{
        responseState[analysedAnswerUser]==4;
        //send money back to creator
        bountyToken.transfer(owner(),userReward[analysedAnswerUser]);
        rewardSetAside=rewardSetAside.sub(userReward[analysedAnswerUser]);
        userReward[analysedAnswerUser]=0;
    }
}

function cashOut() public onlyAfterDisputeWindow { //hands out setaside rewards based on response state
    require(responseState[msg.sender]==1 ||responseState[msg.sender]==2 || responseState[msg.sender]==3 ); // either initial state, disputed (but not resolved), or disputed and resolved positively
    bountyToken.transfer(msg.sender,userReward[msg.sender]);
    userReward[msg.sender]=0;
    rewardSetAside=rewardSetAside.sub(userReward[msg.sender]);
}

function enoughRewardLeft() internal view returns  (bool){
    if(getTotalTokenBountyAmount().sub(rewardSetAside).div(rewardAmount)==0){
        return false;
    }else{
        return true;
    }
}

function getTotalTokenBountyAmount() public view returns(uint256) {
      return bountyToken.balanceOf(address(this));
  }


//HELPER FUNCTIONS

// function to check for an empty string
function checkEmptyString(string _genericString) internal pure returns (bool) {
  bytes memory testGenericString = bytes(_genericString); 
  if (testGenericString.length == 0) {
  	return true;
  } else {
  	return false;
  }
}

}
  



