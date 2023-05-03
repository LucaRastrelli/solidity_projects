// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HelloWorld {
  function sayHello(string memory greet) public pure returns (string memory) {
    string memory hello = "Hello ";

    return string.concat(hello, greet);
  }
}
