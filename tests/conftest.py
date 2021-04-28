import pytest
from brownie import Cafe, accounts


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass

@pytest.fixture(scope="module")
def cafe(Cafe, accounts):
    return Cafe.deploy('123',5,50,50,100,{'from':accounts[0]}) #we suggest not changing the parameters here for deployment.  It won't break the tests, but it
                                                                                                                            #could introduce the need for more tests