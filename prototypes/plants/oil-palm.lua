ITEM {
    type = "item",
    name = "oil-palm-fruit",
    enabled = false,
    icon = "__pyveganism__/graphics/icons/oil-palm-fruit.png",
    icon_size = 64,
    flags = {},
    subgroup = "py-veganism-oil-palm",
    order = "aba",
    stack_size = 200
}

ITEM {
    type = "item",
    name = "oil-palm-fruit-flesh",
    enabled = false,
    icon = "__pyveganism__/graphics/icons/oil-palm-fruit-flesh.png",
    icon_size = 64,
    flags = {},
    subgroup = "py-veganism-oil-palm",
    order = "abb",
    stack_size = 200
}

ITEM {
    type = "item",
    name = "oil-palm-kernel",
    enabled = false,
    icon = "__pyveganism__/graphics/icons/oil-palm-kernel.png",
    icon_size = 64,
    flags = {},
    subgroup = "py-veganism-oil-palm",
    order = "abc",
    stack_size = 200
}

ITEM {
    type = "item",
    name = "oil-palm-kernel-dry",
    enabled = false,
    icon = "__pyveganism__/graphics/icons/oil-palm-kernel-dry.png",
    icon_size = 64,
    flags = {},
    subgroup = "py-veganism-oil-palm",
    order = "abd",
    stack_size = 200
}

ITEM {
    type = "item",
    name = "oil-palm-kernel-open",
    enabled = false,
    icon = "__pyveganism__/graphics/icons/oil-palm-kernel-open.png",
    icon_size = 64,
    flags = {},
    subgroup = "py-veganism-oil-palm",
    order = "abe",
    stack_size = 200
}

FLUID {
    type = "fluid",
    name = "impure-palm-oil",
    icon = "__pyveganism__/graphics/icons/plant-oil.png",
    icon_size = 64,
    default_temperature = 15,
    heat_capacity = "1KJ",
    base_color = {r = 0.694, g = 0.475, b = 0.184},
    flow_color = {r = 0.694, g = 0.475, b = 0.184},
    max_temperature = 100,
    pressure_to_speed_ratio = 0.4,
    flow_to_energy_ratio = 0.59,
    subgroup = "py-veganism-oil-palm"
}

RECIPE {
    type = "recipe",
    name = "grow-oil-palm",
    category = "nursery",
    enabled = false,
    energy_required = 60,
    ingredients = {
        {type = "item", name = "soil", amount = 10},
        {type = "fluid", name = "water", amount = 500}
    },
    results = {
        {type = "item", name = "oil-palm-fruit", amount = 5},
        {type = "item", name = "biomass", amount = 2}
    },
    icons = {{icon = "__pyveganism__/graphics/icons/grow-oil-palm.png"}},
    icon_size = 64,
    subgroup = "py-veganism-oil-palm",
    order = "aba"
}:add_unlock("oil-plants")

RECIPE {
    type = "recipe",
    name = "core-oil-palm",
    category = "crafting",
    enabled = false,
    energy_required = 4,
    ingredients = {
        {type = "item", name = "oil-palm-fruit", amount = 10}
    },
    results = {
        {type = "item", name = "oil-palm-fruit-flesh", amount = 10},
        {type = "item", name = "oil-palm-kernel", amount = 10},
        {type = "item", name = "biomass", amount = 2}
    },
    icons = {{icon = "__pyveganism__/graphics/icons/oil-palm-fruit.png"}},
    icon_size = 64,
    subgroup = "py-veganism-oil-palm",
    order = "aaa"
}:add_unlock("oil-plants")

RECIPE {
    type = "recipe",
    name = "press-oil-palm-fruit-flesh",
    category = py_veganism_globals["plant_oil_pressing_category"],
    enabled = false,
    energy_required = 1,
    ingredients = {
        {type = "item", name = "oil-palm-fruit-flesh", amount = 10}
    },
    results = {
        {type = "fluid", name = "impure-palm-oil", amount = 100},
        {type = "item", name = "biomass-dry", amount = 1}
    },
    icons = {
        { icon = "__pyveganism__/graphics/icons/oil-palm-fruit-flesh.png" }, 
        { icon = "__pyveganism__/graphics/icons/pressing.png" }
    },
    icon_size = 64,
    subgroup = "py-veganism-oil-palm",
    order = "aab"
}:add_unlock("oil-plants")

RECIPE {
    type = "recipe",
    name = "refine-palm-oil",
    category = py_veganism_globals["plant_oil_refining_category"],
    enabled = false,
    energy_required = 4,
    ingredients = {
        {type = "fluid", name = "impure-palm-oil", amount = 100}
    },
    results = {
        {type = "fluid", name = "plant-oil", amount = 70},
        {type = "item", name = "solid-fat", amount = 3}
    },
    icons = {{icon = "__pyveganism__/graphics/icons/oil-palm-fruit.png"}},
    icon_size = 64,
    subgroup = "py-veganism-oil-palm",
    order = "aac"
}:add_unlock("oil-plants")

RECIPE {
    type = "recipe",
    name = "dry-oil-palm-kernel",
    category = "evaporator",
    enabled = false,
    energy_required = 4,
    ingredients = {
        {type = "item", name = "oil-palm-kernel", amount = 10}
    },
    results = {
        {type = "item", name = "oil-palm-kernel-dry", amount = 10}
    },
    icons = {
        {icon = "__pyveganism__/graphics/icons/oil-palm-kernel.png"},
        {icon = "__pyveganism__/graphics/icons/hyperthermic-stress.png"}
    },
    icon_size = 64,
    subgroup = "py-veganism-oil-palm",
    order = "aad"
}:add_unlock("oil-plants")

RECIPE {
    type = "recipe",
    name = "open-oil-palm-kernel",
    category = "ball-mill",
    enabled = false,
    energy_required = 0.5,
    ingredients = {
        {type = "item", name = "oil-palm-kernel-dry", amount = 4}
    },
    results = {
        {type = "item", name = "oil-palm-kernel-open", amount = 5}
    },
    icons = {
        {icon = "__pyveganism__/graphics/icons/oil-palm-kernel-open.png"}
    },
    icon_size = 64,
    subgroup = "py-veganism-oil-palm",
    order = "aae"
}:add_unlock("oil-plants")

RECIPE {
    type = "recipe",
    name = "press-oil-palm-kernel",
    category = py_veganism_globals["plant_oil_pressing_category"],
    enabled = false,
    energy_required = 1,
    ingredients = {
        {type = "item", name = "oil-palm-kernel-open", amount = 10}
    },
    results = {
        {type = "item", name = "solid-fat", amount = 4},
        {type = "fluid", name = "plant-oil", amount = 4},
        {type = "item", name = "biomass-dry", amount = 1} 
    },
    icons = {
        { icon = "__pyveganism__/graphics/icons/oil-palm-kernel-open.png" }, 
        { icon = "__pyveganism__/graphics/icons/pressing.png" }
    },
    icon_size = 64,
    subgroup = "py-veganism-oil-palm",
    order = "aaf"
}:add_unlock("oil-plants")