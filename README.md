# Preserves
A simple wrapper around Defold's save & load functions. Designed to make saving and loading game state dead simple, abstracting away the actual file managment from the user, while maintaining a robust system that supports autosaves, named saves, and, optionally, enforcing type safety on your save data.

## Install
Add this library as a dependency to your Defold project by pasting this link in your `game.project` dependencies field, [more info here:](https://defold.com/manuals/libraries/): 
```
https://github.com/TaylorJC/Preserves/archive/refs/tags/1.0.zip
```

# Usage
## Quickstart
```lua
local preserves = require('preserves') -- Import the module

-- Register some data with the store
preserves.register('player_health')

for i = 1, 10 do
    preserves.register('level_'..tostring(i))
end

-- Store data
preserves.player_health(10)
preserves.level_1({name = 'Breezy Woods', dangerous = false, enemy_count = 0})
-- Alternatively, use set()
preserves.set('level_9', {name = 'Cloud Top Ruins', dangerous = true, enemy_count = 5})

-- Save it to disk
preserves.save() -- defaults to numbered saves e.g. 'save_1'

-- Change your data
preserves.player_health(5)

-- Fetch your stored data
print(preserves.player_health()) -- prints "5"

-- Custom save name
preserves.save('Save_Game')

-- Load your save from disk
preserves.load('save_1') 
print(preserves.get('player_health')) -- equivalent to the fetch above; prints "10"

preserves.load() -- defaults to the last save; in this instance 'Save_Game'

print(preserves.player_health()) -- prints "5"
```

## In Depth
### Requiring
Include the module in your code with:
```lua
local preserves = require('preserves.preserves')
```

This instantiates the `preserves` object with some sane defaults. These include leaving autosaves off, enforcing type safety, and naming your save folder after your project title. 
- Note: In this context autosaves means saving the data store on every write. This could be useful if state is changed infrequently and you want your game to be resilient to forced closures. However, there is a performance trade-off on having a potentially large number of frequent disk writes, which is why this defaults to off. 

### Configuring
The `preserve` object's initial settings can be changed after instantiation with:

```lua
preserves.configure_autosave(true, 5) -- Autosave on, number of autosaves to keep
preserves.configure_save_directory('my_game') -- Folder name for the save files
preserves.configure_type_safety(true) -- Whether stored data is type-enforced once set

-- Reset save directory to default
preserves.configure_save_directory()
```
### Storing data
Your save data is stored internally within the `preserves` object. You can add data to the store by using the `set(key, value)` function or the `register(key)` function which assigns the key with no value. Once a key has been registered or set for the first time, `preserves` adds the key as a function to itself, enabling a less-verbose method of setting and getting data from the store
```lua
preserves.register('player_health') -- Registering enables the shortcuts
preserves.player_health(10) -- Sets the key's value in the data store
preserves.player_health() -- Returns the key's value from the data store

preserves.set('enemy_health', 'low') -- Calls register('enemy_health') internally
preserves.enemy_health('very, very low')
```
Keys in the store must be strings and values can be any type other then functions or tables that contain functions. Ex:
```lua
preserves.set('player_health', 15) -- Number
preserves.set('player_name', 'Jimothy') -- String
preserves.set('player_coordinates', {x = 0.0, y = 1.4}) -- Table
```
- Note: Type safety is enforced after the first value is assigned to a key. Ex: 
```lua
preserves.configure_type_safety(true) -- Defaults to true, just being explicit
preserves.set('player_health', 15) -- player_health now enforced to be a number
preserved.player_health('Healthy!') -- Error
```
### Accessing stored data
Access your stored data with the `get(key)` function or calling the key as a function with no parameters.
```lua
local coords = preserves.get('player_coordinates') -- Using the get function
preserves.player_coordinates() -- Calling the key
```
### Removing stored data
Remove data from the store using the `clear(key)` function. This also removes the shortcut functions from the `preserves` object.
```lua
preserves.clear('player_coordinates') -- Removed 'player_coordinates' from the store
preserves.get('player_coordinates') -- Returns nil
```
### Saving and loading
Once you have some state saved in the store you can save it to disk with the `save(save_name)` function. Leaving the `save_name` parameter empty defaults to saving the file as an increasing numeric entry e.g. 'save_1', 'save_2', etc. Ex:
```lua
preserves.save() -- Saves to 'save_1'
preserves.save('Just beat the boss')
```
Saves can then be restored with the `load(save_name)` function. Leaving the `save_name` parameter empty defaults to loading the most recent save file. Ex:
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
preserves.get_saves() -- {'~/.(save directory)/save_1', etc.} on Linux
```
