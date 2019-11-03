local string = require("__stdlib__/stdlib/utils/string")
local table = require("__stdlib__/stdlib/utils/table")

--[[
    data structures for my pseudo object oriented approach

    global.registered_machines: table
        [LuaEntity.unit_number]: registered_entity

    global.tick_last_finished_research: uint

    registered_entity: table
        ["type"]: int/enum
        ["entity"]: lua_entity (of the machine)
        ["beacons"]: beacons_table
        ["recipe"]: recipe_name
        ["tick_last_refresh"]: tick of the last refresh
        ["pending_humus"]: float
        ["composting_progress"]: float

    beacons_table: table
        [tech_name]: lua_entity (of the beacon)

    relevant_machines: table
        [machine_name]: machine_details

    machine_details: table
        ["is_recipe_dependant"]: bool -- if the modules of this machine depend on the active recipe
        ["affecting_technologies"]: table -- with tech names as strings
]]
--<< Registered Entities >>
local TYPE_BEACONED_MACHINE = 1
local TYPE_COMPOSTING_SILO = 2

--<< Beaconed machine variables (must be final) >>
function lvl_name(technology, level)
    return technology.name .. "-" .. level
end

-- Returns the level for standard upgrade-based techs
function get_tech_level(technology, force)
    local level = 0
    while force.technologies[lvl_name(technology, level + 1)].researched do
        level = level + 1
    end

    --for some reason the level of the infinite technology always returns level + 1
    --and .researched always returns false
    if level == technology.max_finite_level then
        level = force.technologies[lvl_name(technology, (level + 1))].level - 1
    end

    return level
end

-- All the technologies that need to create beacons at runtime
local technologies = {
    ["cultivation-expertise"] = {
        name = "cultivation-expertise",
        machines = {
            ["fawogae-plantation"] = true,
            ["fawogae-plantation-mk02"] = true,
            ["fawogae-plantation-mk03"] = true,
            ["fawogae-plantation-mk04"] = true,
            ["ralesia-plantation"] = true,
            ["botanical-nursery"] = true,
            ["botanical-nursery-mk02"] = true,
            ["botanical-nursery-mk03"] = true,
            ["botanical-nursery-mk04"] = true,
            ["cadaveric-arum"] = true,
            ["kicalk-plantation"] = true,
            ["guar-gum-plantation"] = true
        },
        module = "pyveganism-module-cultivation-expertise",
        beacon = "pyveganism-beacon-cultivation-expertise",
        max_finite_level = 6,
        get_module_count = get_tech_level
    },
    ["plant-breeding"] = {
        name = "plant-breeding",
        machines = {
            ["fawogae-plantation"] = true,
            ["fawogae-plantation-mk02"] = true,
            ["fawogae-plantation-mk03"] = true,
            ["fawogae-plantation-mk04"] = true,
            ["ralesia-plantation"] = true,
            ["botanical-nursery"] = true,
            ["botanical-nursery-mk02"] = true,
            ["botanical-nursery-mk03"] = true,
            ["botanical-nursery-mk04"] = true,
            ["cadaveric-arum"] = true,
            ["kicalk-plantation"] = true,
            ["guar-gum-plantation"] = true
        },
        module = "pyveganism-module-plant-breeding",
        beacon = "pyveganism-beacon-plant-breeding",
        max_finite_level = 4,
        get_module_count = get_tech_level
    }
}

function technology_is_recipe_dependant(technology)
    return technology.recipe_blacklist or technology.recipe_whitelist
end

function machine_is_recipe_dependant(machine_name)
    for _, technology in pairs(technologies) do
        if technology_is_recipe_dependant(technology) and technology.machines[machine_name] then
            return true
        end
    end
    return false
end

function machine_needs_beacons(machine_name)
    for _, technology in pairs(technologies) do
        if technology.machines[machine_name] then
            return true
        end
    end
    return false
end

function get_affecting_technologies(machine_name)
    local ret = {}

    for tech_name, technology in pairs(technologies) do
        if technology.machines[machine_name] then
            table.insert(ret, tech_name)
        end
    end

    return ret
end

function get_relevant_machines()
    local ret, machines = {}, {}

    for _, technology in pairs(technologies) do
        for machine_name, _ in pairs(technology.machines) do
            if not machines[machine_name] then
                table.insert(ret, machine_name)
            end
            machines[machine_name] = true
        end
    end

    return ret
end

function allowes_recipe(technology, recipe)
    if technology.recipe_blacklist then
        return not technology.recipe_blacklist[recipe]
    end

    if technology.recipe_whitelist then
        return technology.recipe_whitelist[recipe]
    end

    return true
end

function get_active_recipe(entity)
    if entity.get_recipe() then
        return entity.get_recipe().name
    else
        return ""
    end
end

--<< Implementation Beaconed Entities >>
-- The current number of modules for this entity for this technology
function current_module_count(entity, technology)
    if not (allowes_recipe(technology, get_active_recipe(entity))) then
        return 0
    end

    return technology:get_module_count(entity.force)
end

-- Creates and returns a beacon for the given entity and technology
function create_beacon_for(entity, technology)
    local beacon =
        entity.surface.create_entity {
        name = technology.beacon,
        position = entity.position,
        force = entity.force
    }

    local module_count = current_module_count(entity, technology)

    if module_count > 0 then
        beacon.get_module_inventory().insert {
            name = technology.module,
            count = module_count
        }
    end

    return beacon
end

-- Creates all beacons for the given entity and returns a beacons_table of them
function create_all_beacons_for(entity)
    local created_beacons = {}

    for _, tech_name in pairs(get_affecting_technologies(entity.name)) do
        local technology = technologies[tech_name]
        local new_beacon = create_beacon_for(entity, technology)
        created_beacons[tech_name] = new_beacon
    end

    return created_beacons
end

function remove_all_beacons_for(registered_entity)
    for _, beacon in pairs(registered_entity.beacons) do
        if beacon.valid then
            beacon.destroy()
        end
    end
    registered_entity.beacons = {}
end

function refresh_beaconed_entity(registered_entity)
    for tech_name, beacon in pairs(registered_entity.beacons) do
        local technology = technologies[tech_name]
        local module_count = current_module_count(registered_entity.entity, technology)

        if beacon.valid then
            local beacon_inventory = beacon.get_module_inventory()
            beacon_inventory.clear()
            if module_count > 0 then
                beacon_inventory.insert {
                    name = technology.module,
                    count = module_count
                }
            end
        else
            -- apparently there are cases where the beacon gets lost (maybe because some other mod accidentally destroys it?)
            -- so we just create a new one
            local new_beacon = create_beacon_for(registered_entity.entity, technology)
            registered_entity.beacons[tech_name] = new_beacon
        end
    end
end

--<< Implementation Composting Silo >>
local compostable_items = require("prototypes.composting-values")

function analyze_silo_inventory(registered_silo)
    local contents = registered_silo.entity.get_inventory(defines.inventory.chest).get_contents()

    local count = 0
    local type_count = 0
    local humus_count = 0
    for item_name, item_count in pairs(contents) do
        if compostable_items[item_name] then
            count = count + item_count
            type_count = type_count + 1
        end
        if item_name == "humus" then
            humus_count = humus_count + item_count
        end
    end

    return {count = count, type_count = type_count, humus_count = humus_count}
end

local composting_coefficient = 1. / 600. / 200. -- 1 Humus every 10 Seconds (600 ticks) when 200 Items are in the silo
function get_composting_progress(item_count, item_types_count, humus_count, time)
    return item_count * item_types_count * time * composting_coefficient *
        math.max(1., math.min(5., item_count / 2000.)) * math.min(5, 1 + humus_count * 0.001)
end

function remove_compostable_items(registered_silo, type_count)
    if registered_silo.composting_progress < 1 then
        return
    end
    local inventory = registered_silo.entity.get_inventory(defines.inventory.chest)

    local index_to_remove = math.random(type_count)
    local count = 1

    for item_name, _ in pairs(inventory.get_contents()) do
        if compostable_items[item_name] then
            if count == index_to_remove then
                local removed_count =
                    inventory.remove {name = item_name, count = math.floor(registered_silo.composting_progress)}
                registered_silo.composting_progress = registered_silo.composting_progress - removed_count
                registered_silo.pending_humus =
                    registered_silo.pending_humus + removed_count * compostable_items[item_name]
                break
            else
                count = count + 1
            end
        end
    end
end

function process_compostable_items(registered_silo)
    local delta_time = game.tick - registered_silo.tick_last_refresh
    local details = analyze_silo_inventory(registered_silo)
    registered_silo.composting_progress =
        registered_silo.composting_progress + get_composting_progress(details.count, details.type_count, details.humus_count, delta_time)
    remove_compostable_items(registered_silo, details.type_count)
end

function distribute_humus(registered_silo)
    local count = math.floor(registered_silo.pending_humus)
    if count < 1 then
        return
    end

    local inventory = registered_silo.entity.get_inventory(defines.inventory.chest)
    local item_stack = {name = "humus", count = count}

    if inventory.can_insert(item_stack) then
        local inserted_count = inventory.insert(item_stack)
        registered_silo.pending_humus = registered_silo.pending_humus - inserted_count
    end
end

function refresh_composting_silo(registered_silo)
    if registered_silo.pending_humus < 1000 then -- stop consuming material if a lot of humus is generated, but cannot be inserted
        process_compostable_items(registered_silo)
    end
    distribute_humus(registered_silo)
end

--<< Implementation Register >>
function refresh(registered_entity)
    if not registered_entity.entity.valid then
        unregister(registered_entity)
        return
    end

    if registered_entity.type == TYPE_BEACONED_MACHINE then
        refresh_beaconed_entity(registered_entity)
    elseif registered_entity.type == TYPE_COMPOSTING_SILO then
        refresh_composting_silo(registered_entity)
    end
    registered_entity.tick_last_refresh = game.tick
end

-- Refreshes all registered entities, calling it will likely cause a lag spike
function refresh_all_entries()
    for _, registered_entity in pairs(global.registered_machines) do
        refresh(registered_entity)
    end
end

-- Adds the machine to the register and creates all the needed beacons
function register_beaconed_machine(entity)
    local beacons = create_all_beacons_for(entity)
    local recipe = get_active_recipe(entity)

    global.registered_machines[entity.unit_number] = {
        type = TYPE_BEACONED_MACHINE,
        entity = entity,
        beacons = beacons,
        recipe = recipe,
        tick_last_refresh = game.tick
    }
end

-- Adds the composting silo to the register
function register_composting_silo(entity)
    global.registered_machines[entity.unit_number] = {
        type = TYPE_COMPOSTING_SILO,
        entity = entity,
        tick_last_refresh = game.tick,
        pending_humus = 0.,
        composting_progress = 0.
    }
end

-- Removes the machine from the register and removes all it's beacons
function unregister(registered_entity)
    if registered_entity.type == TYPE_BEACONED_MACHINE then
        remove_all_beacons_for(registered_entity)
    end
    global.registered_machines[registered_entity.entity.unit_number] = nil
end

-- Eventhandler machine built
function on_entity_built(event)
    --https://forums.factorio.com/viewtopic.php?f=34&t=73331#p442695
    if event.created_entity then
        entity = event.created_entity
    elseif event.entity then
        entity = event.entity
    elseif event.destination then
        entity = event.destination
    end

    if not entity or not entity.valid then
        return
    end

    if machine_needs_beacons(entity.name) then
        register_beaconed_machine(entity)
    end
    if entity.name == "composting-silo" then
        register_composting_silo(entity)
    end
end

-- Eventhandler machine removed
function on_entity_removed(event)
    local registry = global.registered_machines[event.entity.unit_number]

    if registry then
        unregister(registry)
    end
end

-- Eventhandler research
function on_research_finished(event)
    global.tick_last_finished_research = game.tick

    if settings.global["pyveganism-refresh-beacons-on-finished-research"].value then
        for _, tech in pairs(technologies) do
            if string.starts_with(event.research.name, tech.name) then
                refresh_all_entries()
                return
            end
        end
    end
end

-- Eventhandler recipe change (custom)
function on_recipe_change(registered_entity)
    if machine_is_recipe_dependant(registered_entity.entity.name) then
        refresh(registered_entity)
    end
end

function check_registered_beaconed_entity(registered_entity)
    local entity = registered_entity.entity
    local current_recipe = get_active_recipe(entity)
    local last_recipe = registered_entity.recipe

    if not (current_recipe == last_recipe) then
        registered_entity.recipe = current_recipe
        on_recipe_change(registered_entity)
    end

    if global.tick_last_finished_research > registered_entity.tick_last_refresh then
        refresh(registered_entity)
    end
end

function check_registered_entity(registered_entity)
    local entity = registered_entity.entity

    if not entity.valid then
        unregister(registered_entity)
        return
    end

    if registered_entity.type == TYPE_BEACONED_MACHINE then
        check_registered_beaconed_entity(registered_entity)
    end
    if registered_entity.type == TYPE_COMPOSTING_SILO then
        refresh(registered_entity)
    end
end

-- Checks some entries for validity and custom events
function tick()
    local next = next
    local count = 0
    local register = global.registered_machines
    local index = global.last_index
    local current_entity
    local number_of_checks = global.max_checks

    if index and register[index] then
        current_entity = register[index] -- continue looping
    else
        index, current_entity = next(register, nil) -- begin a new loop at the start (nil as a key returns the first pair)
    end

    while index and count < number_of_checks do
        check_registered_entity(current_entity)
        index, current_entity = next(register, index)
        count = count + 1
    end

    global.last_index = index
end

function on_suspected_recipe_change(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local registered_entity = global.registered_machines[entity.unit_number]
    if registered_entity then
        check_registered_entity(registered_entity)
    end
end

function init()
    global.registered_machines = {}

    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(
            surface.find_entities_filtered {
                name = {"pyveganism-beacon-cultivation-expertise", "pyveganism-beacon-plant-breeding"}
            }
        ) do
            entity.destroy()
        end
    end

    local relevant_machines = get_relevant_machines()
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered {name = relevant_machines}) do
            register_beaconed_machine(entity)
        end
    end
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered {name = "composting-silo"}) do
            register_composting_silo(entity)
        end
    end

    global.tick_last_finished_research = 0
    global.max_checks = settings.global["pyveganism-checks-per-tick"].value * 10
    global.PYV_VERSION = game.active_mods["pyveganism"]
end

function load()
    global.max_checks = settings.global["pyveganism-checks-per-tick"].value * 10
    if not global.max_checks then --just to be sure
        global.max_checks = 50
    end
end

function settings_update(event)
    global.max_checks = settings.global["pyveganism-checks-per-tick"].value * 10
end

function configuration_change(event)
    -- Check if the stored version number equals the version of the loaded mod
    if game.active_mods["pyveganism"] ~= global.PYV_VERSION then
        -- I published a new version. Reset recipes, techs and tech effects in case I changed something.
        -- I do that a lot and don't want to forget a migration file.
        global.PYV_VERSION = game.active_mods["pyveganism"]

        for _, force in pairs(game.forces) do
            force.reset_recipes()
            force.reset_technologies()
            force.reset_technology_effects()
        end
    end
end

--<< Eventhandlers >>
-- initialisation
script.on_init(init)

-- placement
script.on_event(defines.events.on_built_entity, on_entity_built)
script.on_event(defines.events.on_robot_built_entity, on_entity_built)
script.on_event(defines.events.on_entity_cloned, on_entity_built)
script.on_event(defines.events.script_raised_built, on_entity_built)
script.on_event(defines.events.script_raised_revive, on_entity_built)

-- removing
script.on_event(defines.events.on_player_mined_entity, on_entity_removed)
script.on_event(defines.events.on_robot_mined_entity, on_entity_removed)
script.on_event(defines.events.on_entity_died, on_entity_removed)
script.on_event(defines.events.script_raised_destroy, on_entity_removed)

-- research finishes
script.on_event(defines.events.on_research_finished, on_research_finished)

-- maintenance routines
script.on_nth_tick(10, tick)
script.on_event(defines.events.on_runtime_mod_setting_changed, settings_update)
script.on_configuration_changed(configuration_change)
script.on_load(load)

-- events that could mean a recipe change
script.on_event(defines.events.on_gui_closed, on_suspected_recipe_change)
script.on_event(defines.events.on_entity_settings_pasted, on_suspected_recipe_change)

--[[
    global.blood_donations: table
        [player_name]: table (ticks as uint when the last donations occured)
]]
--<< Sample crafting effects >>
function log_blood_donation(player_name)
    if not global.blood_donations then
        global.blood_donations = {}
    end
    if not global.blood_donations[player_name] then
        global.blood_donations[player_name] = {}
    end

    table.insert(global.blood_donations[player_name], game.tick)
end

function get_count_of_recent_blood_donations(player_name)
    local count = 0
    local current_tick = game.tick
    for _, tick in pairs(global.blood_donations[player_name]) do
        local time_past = current_tick - tick
        if time_past < 216000 then --216000 is 60 minutes (3600 seconds) at 60 ticks per second
            count = count + 1
        else
            global.blood_donations[player_name] = nil
        end
    end

    return count
end

function give_sticker_to(player, sticker_name)
    player.surface.create_entity {
        name = sticker_name,
        position = player.position,
        force = player.force,
        target = player.character
    }
end

function execute_blood_donation_effects(player, donation_count)
    local player_entity = player.character
    if not player_entity or not player_entity.valid or not player_entity.health then
        return
    end

    -- stickers first, because the player could die from the damage
    for i = 1, math.min(donation_count, 5) do
        give_sticker_to(player, "blood-donation-" .. i)
    end

    local damage = donation_count * 0.19 * player_entity.prototype.max_health
    player_entity.damage(damage, player_entity.force)
end

function on_blood_donation(player_index)
    local player = game.get_player(player_index)
    log_blood_donation(player.name)
    local count = get_count_of_recent_blood_donations(player.name)
    execute_blood_donation_effects(player, count)
end

function on_crafted_item(event)
    local recipe = event.recipe.name

    if recipe == "generate-engineer-blood" then
        on_blood_donation(event.player_index)
    end
end

script.on_event(defines.events.on_player_crafted_item, on_crafted_item)
