# ChatMe
A simple tcp chat app.

## Getting started

In one terminal window start the application:
```
mix run --no-halt
```

In another window run telnet
```
telnet 127.0.0.1 4444
```

## Example

```
telnet 127.0.0.1 4444
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
Welcome to my chat server! What is your nickname?
jim
You are connected with 0 other users: []
*bob has joined the chat*
[04:34:55] <bob> hey @jim
sup
[04:35:26] <bob> what are we doing today?
not sure
Connection closed by foreign host.
```