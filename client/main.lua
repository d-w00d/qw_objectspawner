local obj = require 'client.object'

local function newObject() 
    local input = lib.inputDialog('Synced Object', {
        {
            type = 'input',
            label = 'Object Name',
            required = true,
        },
    })

    if not input then 
        lib.showContext('object_menu_main')
        return
    end

    local object = tostring(input[1])

    local objectModel = object and GetHashKey(object)

    if not IsModelInCdimage(objectModel) then
        lib.notify({
            title = 'Object Spawner',
            description = ("The object \"%s\" is not in cd image, are you sure this exists?"):format(objectModel),
            type = 'error'
        })
        return
    end

    obj.previewObject(objectModel, object)
end
local function confirmEdit(handle, id, name, netId)
    SetEntityDrawOutline(handle, true)
    SetEntityDrawOutlineColor(255, 0, 0, 255)
    lib.registerContext({
        id = 'object_confirm_edit',
        title = ('Edit: %s'):format(name),
        options = {
            {
                title = 'Confirm',
                icon = 'check',
                onSelect = function()
                    SetEntityDrawOutline(handle, false)
                    obj.editPlaced(id, netId)
                end,
            },
            {
                title = 'Delete',
                icon = 'trash',
                onSelect = function()
                    SetEntityDrawOutline(handle, false)
                    obj.removeObject(id, netId)
                end,
            },
            {
                title = 'Cancel',
                icon = 'times',
                onSelect = function()
                    SetEntityDrawOutline(handle, false)
                    lib.showContext('object_menu_s')
                end,
            }
        },
    })

    lib.showContext('object_confirm_edit')
end

local function editObjects() 
    local options = {}
    local placed = obj.getPlaced()

    if #placed == 0 then
        lib.notify({
            title = 'Object Spawner',
            description = 'No objects placed',
            type = 'error'
        })
        return
    end

    for i = 1, #placed do
        local netId = placed[i]
        local ent = NetworkGetEntityFromNetworkId(netId)
        local v = Entity(ent).state?.object
        if not v then goto continue end
        local dbId = v.dbId
        local fmtCoords = ('coords: %s, %s, %s'):format(v.coords.x, v.coords.y, v.coords.z)
        options[#options + 1] = {
            title = v.model,
            description = fmtCoords,
            icon = 'object-ungroup',
            onSelect = function()
                confirmEdit(ent, dbId, v.model, netId)
            end,
            metadata = {
                {value = dbId, label = 'Database ID'},
            }
        }
        ::continue::
    end

    lib.registerContext({
        id = 'object_menu_s',
        title = ('Placed Objects (%s Total)'):format(#placed),
        menu = 'object_menu_main',
        options = options,
    })

    lib.showContext('object_menu_s')
end

local function removeAllObjects() 
    local deleted = lib.callback.await('objects:deleteAllObjects', 100)

    if deleted then
        lib.notify({
            title = 'Object Spawner',
            description = 'All objects removed',
            type = 'success'
        })
    end
end

RegisterNetEvent("qw_decorator:client:open", function() 
    if GetInvokingResource() then return end -- only allow this to be called from the server
    local placed = obj.getPlaced()
    lib.registerContext({
        id = 'object_menu_main',
        title = 'Synced Objects',
        options = {
            {
                title = 'Spawn New Object',
                description = 'spawn a new object and save it to the database',
                icon = 'object-ungroup',
                onSelect = function()
                    newObject()
                end,
            },
            {
                title = 'Edit Existing Objects',
                description = 'edit objects that have been placed',
                icon = 'object-ungroup',
                onSelect = function()
                    editObjects()
                end,
            },
            {
                title = 'Delete Existing Objects',
                description = 'delete objects that have been placed',
                icon = 'object-ungroup',
                disabled = #placed == 0,
                onSelect = function()
                    removeAllObjects()
                end,
            }
        },
    })

    lib.showContext('object_menu_main')
end)