# lua sc2 ai 
a lua module for creating starcraft 2 bots 

__supported versions__
- lua5.1

## installation


<span style="color:red; font-weight:bold;">⚠️ Warning: </span> the lua-websockets library for lua5.1 has an issue which hasn't been fixed yet 

for the bot to work properly you'll need to change 
```lua
    fill_length = fill_length - 2
```
to 
```lua
    fill_length = fill_length - 2 + frame.length
```
in `lua-http/http/websocket.lua` (line 244)

to install the rock simply just run 
```bash
    $ luarocks install luasc2ai
```
## supported platforms 
### windows
In theory this module should work with windows, but I would recommend using running this on wsl since a lot of the dependencies are problematic to make work on windows 
### wsl
This module supports wsl. just be sure to set the __SC2IP , SC2PORT__ and __SC2LAUNCHPORT__ environment varraibles

    SC2IP - the ip where starcraft 2 would expect the connection, most commonly you want it to set to the wsl virtual router 
    SC2PORT - the port used for communication with starcraft 2
    SC2LAUNCHPORT - a free port for the runner sc2runner.ps1 script to use on windows 


## basic usage 
be sure to check out the `examples` directory 
    
- create an agent by calling sc2ai.new() 
- set up any state that the agent will have to use 
- call sc2ai:loop() and pass in a call back where you will define the behavirour of the bot 
- - if realtime mode is not enabled then you will have to explicitly call sc2ai:step() before returning 

## Dependencies
This module depends on `lua-protobuff` and `lua-http`
