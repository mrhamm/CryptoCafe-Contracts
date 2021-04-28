This file contains the contracts for Crypto-Cafe.net

Project folder uses Brownie - we recommend installing brownie at https://eth-brownie.readthedocs.io/en/stable/index.html

**Requirements**
This project does not contain a requirements file.  You should make sure to have the latest versions of  web3.py, brownie, and OpenZeppelin. 

**OpenZeppelin** 
The Cafe contract requires the OpenZeppelin library, specifically the ERC-1155 and Enumerable set contracts.  Be sure 
to edit the import statements in Cafe.sol to reflect the location of your openzeppelin library.  

**Unit Tests**
Tests are written using pytest and can be run with $brownie test.    We do not include standard tests for ERC-1155, and 
refer to the OpenZeppelin Library for these.  