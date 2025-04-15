# Preserves
A simple wrapper around Defold's save & load functions. Designed to make saving and loading game state dead simple, abstracting away the actual file managment from the user, while maintaining a robust system that supports autosaves, named saves, and, optionally, enforcing type safety on your save data.

## Install
Add this library as a dependency to your Defold project by pasting this link in your `game.project` dependencies field, [more info here:](https://defold.com/manuals/libraries/): 
```
https://github.com/TaylorJC/Preserves/releases/tag/1.0.zip
```

## Usage
# Quickstart
```lua
local preserves = require('preserves') -- Import the module

-- Add some data to the store
preserves.set('player_health', 10)
preserves.set('level_1', { name = 'Cloud_Top_Ruins', dangerous = true, enemy_count = 5})

-- Save it to disk
preserves.save() -- defaults to numbered saves e.g. 'save_1'

-- Change your data
preserves.set('player_health', 5)

-- Fetch your stored data
print(preserves.player_health) -- prints "5"

-- Custom save name
preserves.save('Save_Game')

-- Load your save from disk
preserves.load('save_1') 
print(preserves.get('player_health')) -- equivalent to the fetch above; prints "10"

preserves.load() -- defaults to the last save

print(preserves.player_health) -- prints "5"
```

## In Depth
Include the module in your code with:
```lua
local preserves = require('preserves.preserves')
```

This instantiates the `preserves` object with some sane defaults. These include leaving autosaves off, enforcing type safety, and naming your save folder after your project title. 
- Note: in this context autosaves means saving the data store on every write. This could be useful if state is changed infrequently and you want your game to be resilient to forced closures. However, there is a performance trade-off on having a potentially large number of frequent disk writes, which is why this defaults to off. 

These settings can be changed after instantiation with:

```lua
preserves.configure_autosave(true, 5) -- Should autosave?, Number of autosaves to keep
preserves.configure_save_directory('my_game') -- Folder name for the save files
preserves.configure_type_safety(true) -- Whether set data is type-enforced once set

-- Reset save directory to default
preserves.configure_save_directory()
```
Your save data is stored internally within the `preserves` object. You can add data to the store by using the `set(key, value)` function or the `register(key)` function which assigns the key with no value, while setting up some shortcut functions to set and get that data item.
Keys in the store must be strings and values can be any type other then functions or tables that contain functions. Ex:
```lua
preserves.set('player_health', 15) -- Number
preserves.set('player_name', 'Jimothy') -- String
preserves.set('player_coordinates', {x = 0.0, y = 1.4}) -- Table

preserves.register('player_dead') -- Sets key in the store with a nil value; enables shortcut functions
preserves.set_player_dead(true) -- Enabled by pre-registering the key
preserves.player_dead -- Enabled by pre-registering the key; Returns true
```
- Note: The table access notation is only available for a key after doing an initial `set(key, value)` or `register(key)` call. The helpers are also only shortcuts to the `set(key, value)` and `get(key)` functions and DO NOT provide the user with direct access to the data store. Thus, you cannot add data to the store, nor set data using the get shortcut notation, only retrieve it. Ex:
```lua
preserves.set('player_health', 10) -- Actually set the store value to 10
preserves.player_health = 5 -- Only overwrote the get('player_health') function for the player_health key
preserves.get('player_health') -- Returns 10
preserves.player_health -- Returns 5 instead of the true stored value
```
- Note: Type safety is enforced after the first value is assigned to a key. Ex: 
```lua
preserves.configure_type_safety(true) -- Defaults to true, just being explicit
preserves.set('player_health', 15) -- player_health now enforced to be a number
preserved.set('player_health', 'Healthy!') -- Errors with "Type Safety Error: Tried to assign a value of type string to player_health with enforced type number"
```
Once you have some state saved in the store you can save it to disk with the `save(save_name)` function. Leaving the `save_name` parameter empty defaults to saving the file as an increasing numeric entry e.g. 'save_1', 'save_2', etc. Ex:
```lua
preserves.save() -- Saves to 'save_1'
preserves.save('Just beat the boss')
```
Saved can then be restored with the `load(save_name)` function. Leaving the `save_name` parameter empty defaults to loading the most recent save file. Ex:
```lua
preserves.load() -- Loads 'Just beat the boss'
preserves.load('save_1')
```
If you want to get a list of all save file names, to display to the user in a load game screen for example, use the `get_save_names()` function:
```lua
preserves.get_save_names() -- Returns {'save_1', 'Just beat the boss'}
```
Alternatively, you can get a list of all save file paths with `get_saves()`. Ex:
```lua
preserves.get_saves() -- Returns {'home/(username)/.(game title)/save_1', 'home/(username)/.(game title)/Just beat the boss'} on Linux, for example
```
Access your stored data with the `get(key)` function or using table access notation:
```lua
local coords = preserves.get('player_coordinates') -- Using the get function
preserves.player_health -- Using table access notation
```
