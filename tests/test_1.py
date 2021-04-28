import pytest
from time import sleep
import brownie

def test_grindFlour(cafe,accounts):
    assert cafe.balanceOf(accounts[0],0) == 0
    cafe.grindFlour()
    assert cafe.balanceOf(accounts[0],0) == cafe.grindReward()
    with brownie.reverts('You did this already today!'):
        cafe.grindFlour()



def test_starterCreation(cafe,accounts):
    cafe.grindFlour()
    cafe.grindFlour({'from':accounts[1]})
    cafe.createStarter()
    cafe.createStarter({'from':accounts[1]})
    assert cafe.balanceOf(accounts[0],0) == cafe.grindReward()-cafe.createCost()
    assert cafe.balanceOf(accounts[0],1) == 1
    assert cafe.balanceOf(accounts[1],1) == 0
    assert cafe.getCreatorAddress(1) == accounts[0]
    assert cafe.getIsAutoFed(1) == False
    assert cafe.getCreatorAddress(2) == accounts[1]

def test_starterFeeding(cafe, accounts):
    cafe.grindFlour()
    cafe.createStarter()
    CreatedAt = cafe.getCreationTime(1)
    TimeOfDeath1 = cafe.getTimeOfDeath(1)
    sleep(2)
    cafe.feedStarter(1)
    TimeOfDeath2 = cafe.getTimeOfDeath(1)
    CreatedAt2 = cafe.getCreationTime(1)
    assert CreatedAt == CreatedAt2
    assert TimeOfDeath2 >= (TimeOfDeath1 + 2)
    assert cafe.balanceOf(accounts[0],0)==0
    assert TimeOfDeath2 >= CreatedAt + 2 + cafe.timescale()

def test_feedOtherStarter(cafe,accounts):
    cafe.grindFlour()
    cafe.createStarter()
    cafe.grindFlour({'from':accounts[1]})
    with brownie.reverts('This Id number is not associated with one of your starters, please try with a valid id.'):
        cafe.feedStarter(1,{'from':accounts[1]})
    with brownie.reverts('This Id number is not associated with one of your starters, please try with a valid id.'):
        cafe.feedStarter(2)
   

def test_starterDeath(cafe, accounts):
    cafe.grindFlour()
    cafe.createStarter()
    sleep(6)
    with brownie.reverts("Your starter is dead!  You should have fed it sooner :( ."):
        cafe.feedStarter(1)
    cafe.grindFlour()
    with brownie.reverts("Your starter is dead!  You should have fed it sooner :( ."):
        cafe.splitStarter(1)
    
def test_starterSplitting(cafe,accounts):
    cafe.grindFlour()
    sleep(6)
    cafe.grindFlour()
    cafe.createStarter()
    cafe.splitStarter(1)
    assert cafe.balanceOf(accounts[0],0)  == 2*cafe.grindReward()-2*cafe.createCost()-2*cafe.feedCost()
    assert cafe.balanceOf(accounts[0],1) == 1
    assert cafe.balanceOf(accounts[0],2) == 1
    assert cafe.getChildCount(1) ==1
    assert cafe.getChildCount(2) ==0
    assert cafe.getCreationTime(1) == cafe.getCreationTime(2)

def test_splitOtherStarter(cafe,accounts):
    cafe.grindFlour()
    cafe.grindFlour({'from':accounts[1]})
    sleep(6)
    cafe.grindFlour({'from':accounts[1]})
    cafe.createStarter()
    with brownie.reverts("This Id number is not associated with one of your starters, please try with a valid id."):
        cafe.splitStarter(1,{'from':accounts[1]})
    with brownie.reverts("This Id number is not associated with one of your starters, please try with a valid id."):
        cafe.splitStarter(2)

def test_autoFeed(cafe,accounts): 
    cafe.grindFlour({'from':accounts[1]})
    sleep(7)
    cafe.grindFlour({'from':accounts[1]})
    sleep(7)
    cafe.grindFlour({'from':accounts[1]})
    cafe.createStarter({'from':accounts[1]})
    cafe.autoFeed(2,1,{'from':accounts[1]})
    assert cafe.balanceOf(accounts[1],0) == 3*cafe.grindReward()- cafe.createCost() - 4*cafe.feedCost()
    assert cafe.balanceOf(accounts[0],0) == 2*cafe.feedCost()
    assert cafe.isPlayerAutoFeeding(accounts[1])==True
 
    
