import pytest
import brownie
from time import sleep


def test_playerScore(cafe,accounts):
    cafe.grindFlour()
    cafe.grindFlour({'from':accounts[1]})
    sleep(7)
    cafe.grindFlour()
    cafe.grindFlour({'from':accounts[1]})
    cafe.createStarter()
    sleep(2)
    cafe.publishNewRecipe('bread',0,[1],[1])
    cafe.eatBakedGood(1,1)
    assert cafe.playerHighScore(0) == accounts[0]
    cafe.createStarter({'from':accounts[1]})
    cafe.createStarter({'from':accounts[1]})
    sleep(2)
    cafe.bakeExistingRecipe(1,[2],{'from':accounts[1]})
    cafe.bakeExistingRecipe(1,[3],{'from':accounts[1]})
    cafe.eatBakedGood(1,2,{'from':accounts[1]})
    assert cafe.playerHighScore(0) == accounts[1]
    assert cafe.playerHighScore(1) == accounts[0]

def test_oldestStarter(cafe,accounts):
    cafe.grindFlour()
    cafe.grindFlour({'from':accounts[1]})
    cafe.createStarter()
    sleep(3)
    cafe.feedStarter(1)
    assert cafe.starterHighScore(0) == 1
    sleep(7)
    cafe.grindFlour({'from':accounts[1]})
    cafe.createStarter({'from':accounts[1]})
    sleep(3)
    cafe.feedStarter(2,{'from':accounts[1]})
    sleep(3)
    cafe.feedStarter(2,{'from':accounts[1]})
    assert cafe.starterHighScore(0) == 2
    assert cafe.starterHighScore(1) == 1

def test_mostUsedRecipe(cafe,accounts):
    cafe.grindFlour()
    sleep(6)
    cafe.grindFlour()
    sleep(6)
    cafe.createStarter()
    cafe.createStarter()
    cafe.createStarter()
    sleep(2)
    cafe.publishNewRecipe("Bread1",10,[1],[1])
    assert cafe.recipeHighScore(0) == 1
    cafe.publishNewRecipe("Bread2",10,[1],[2])
    cafe.bakeExistingRecipe(2,[3])
    assert cafe.recipeHighScore(0) == 2
    assert cafe.recipeHighScore(1) == 1





    

