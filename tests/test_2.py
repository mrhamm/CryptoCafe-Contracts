import pytest
import brownie
from time import sleep

def test_recipeCreate(cafe,accounts):
    cafe.grindFlour()
    sleep(7)
    cafe.grindFlour()
    cafe.createStarter()
    cafe.createStarter()
    assert cafe.balanceOf(accounts[0],1) == 1 
    sleep(3)
    cafe.publishNewRecipe("Ben's Bread", 10, [1,2],[1,2])
    assert cafe.balanceOf(accounts[0],1) == 0
    assert cafe.balanceOf(accounts[0],0) == 2*cafe.grindReward()-2*cafe.createCost()-10
    index = 57896044618658097711785492504343953926634992332820282019728792003956564819968 + 1
    assert cafe.balanceOf(accounts[0],index) == 1
    assert cafe.getRecipeName(1) == "Ben's Bread"
    assert cafe.getIngredientByIndex(1,0) == 1
    assert cafe.getIngredientByIndex(1,1) == 2
    assert cafe.getTimesBaked(1) == 1
    assert cafe.getFlourRequired(1) == 10
    assert cafe.getRecipeCreator(1) == accounts[0]


def test_recipeTooLarge(cafe,accounts):
    ages = [1,2,3,4,5,6,7,8,9,10,11]
    with brownie.reverts('You can only have up to 10 ingredients!'):
        cafe.publishNewRecipe("Bread",10,ages,ages)
def test_incorrectIngredients(cafe,accounts):
    cafe.grindFlour()
    sleep(7)
    cafe.grindFlour()
    sleep(7)
    cafe.grindFlour()
    cafe.createStarter()
    cafe.createStarter()
    cafe.createStarter()
    cafe.createStarter()
    cafe.createStarter()
    sleep(3)
    cafe.publishNewRecipe("Bread",10,[1,2],[1,2])
    with brownie.reverts("You haven't added the right number of starters to the batch!"):
        cafe.bakeExistingRecipe(1,[3])
    with brownie.reverts("You haven't added the right number of starters to the batch!"):
        cafe.bakeExistingRecipe(1,[3,4,5])


def test_bakeExistingRecipe(cafe,accounts):
    cafe.grindFlour()
    cafe.grindFlour({'from':accounts[1]})
    cafe.createStarter()
    cafe.createStarter({'from':accounts[1]})
    sleep(2)
    cafe.publishNewRecipe("Bread",10,[1],[1])
    cafe.bakeExistingRecipe(1,[2],{'from':accounts[1]})
    index = 57896044618658097711785492504343953926634992332820282019728792003956564819968 + 1
    assert cafe.balanceOf(accounts[1],0)==40
    assert cafe.balanceOf(accounts[1],index)==1
    assert cafe.getTimesBaked(1) == 2

def test_eatBakedGood(cafe,accounts):
    cafe.grindFlour()
    sleep(6)
    cafe.grindFlour()
    sleep(6)
    cafe.grindFlour()
    cafe.createStarter()
    cafe.createStarter()
    cafe.createStarter()
    sleep(2)
    cafe.publishNewRecipe("Bread", 10, [1],[1])
    cafe.bakeExistingRecipe(1,[2])
    cafe.bakeExistingRecipe(1,[3])
    index = 57896044618658097711785492504343953926634992332820282019728792003956564819968 + 1
    assert cafe.balanceOf(accounts[0],index)==3
    Score1 = cafe.getPlayerScore(accounts[0])
    assert Score1==0
    cafe.eatBakedGood(1,1)
    Score2 = cafe.getPlayerScore(accounts[0])
    assert cafe.balanceOf(accounts[0],index)==2
    assert Score2 ==1
    assert cafe.getNumberEaten(1)==1
    cafe.eatBakedGood(1,2)
    assert cafe.getPlayerScore(accounts[0]) ==3
    assert cafe.balanceOf(accounts[0],index)==0


def test_eatFakeItem(cafe,accounts):
    with brownie.reverts("You don't have that many of those to eat!"):
        cafe.eatBakedGood(1,1)



def test_bakeNewWithDead(cafe,accounts):
    cafe.grindFlour()
    cafe.createStarter()
    sleep(7)
    with brownie.reverts('Your starters are not all alive, you must use a living ingredient!!'):
        cafe.publishNewRecipe("Bread",10,[1],[1])

def test_bakeExistingWithDead(cafe,accounts):
    cafe.grindFlour()
    sleep(6)
    cafe.grindFlour()
    cafe.createStarter()
    cafe.createStarter()
    sleep(2)
    cafe.publishNewRecipe("Bread",10,[1],[1])
    sleep(4)
    with brownie.reverts('Your starters are not all alive, you must use a living ingredient!!'):
        cafe.bakeExistingRecipe(1,[2])



  

