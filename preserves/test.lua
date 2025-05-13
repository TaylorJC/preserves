local preserves = require "preserves_l"

preserves.init('C:/Temp/')

preserves.register('health')

preserves.health(10)

print(tostring(preserves.health()))

preserves.save('save_1')

preserves.health(15)

print(tostring(preserves.health()))

if preserves.load() then
    print(tostring(preserves.health()))
end

