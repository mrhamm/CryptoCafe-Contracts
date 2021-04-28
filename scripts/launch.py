
from brownie import Cafe, accounts, CafeEscrow
from web3 import Web3
from time import sleep


#ganache_url = "HTTP://127.0.0.1:8545"
#web3 = Web3(Web3.HTTPProvider(ganache_url))
#print(web3.isConnected())

#token = '0xe24D48565dF3Dbf082162F53EeC9E4aE15C4e891'
#starter = '0xED36532B563443d9BCab878d0956a010040cf9E0'

acct = accounts.load('RinkebyDev')

cafe = Cafe.deploy("",86400,100,50,1000,{'from': acct},publish_source=True)

#starter = Starter.deploy(token,'Starter','STRT',{'from':acct}, publish_source=True )
#token.approve(starter, 500)
'''
escrow = CafeEscrow.deploy({'from':accounts[0]})
print(web3.eth.getBalance(str(accounts[0])))
escrow.depositFunds({'from':accounts[0],'value':2e18})
print(web3.eth.getBalance(str(accounts[0])))
escrow.takeAllowance({'from':accounts[1]})
print(web3.eth.getBalance(str(accounts[1])))
escrow.takeAllowance({'from':accounts[1]})'''
