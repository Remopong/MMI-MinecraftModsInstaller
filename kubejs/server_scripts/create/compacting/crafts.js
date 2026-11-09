ServerEvents.recipes(e => {
    // Magnetite Block (Fixed using your custom syntax)
    e.custom({ "type": "create:compacting", "heat_requirement": "heated", "ingredients": [{ "item": "minecraft:basalt" },{ "item": "minecraft:iron_ingot" },{ "item": "minecraft:iron_ingot" },{ "item": "minecraft:iron_ingot" },{ "item": "minecraft:iron_ingot" },{ "item": "minecraft:redstone" },{ "item": "minecraft:redstone" },{ "item": "minecraft:redstone" },{ "item": "minecraft:redstone" } ], "results": [{ "id": "create_new_age:magnetite_block" }]})
    //Gabbro
    e.custom({ "type": "create:compacting", "ingredients": [{ "item": "minecraft:granite" }, { "item": "minecraft:dripstone_block" }, { "type": "fluid_stack", "amount": 100, "fluid": "minecraft:lava" }], "results": [{ "id": "create_d2d:gabbro" }] })
    //Dolomite
    e.custom({ "type": "create:compacting", "ingredients": [{ "item": "minecraft:calcite" }, { "item": "create:limestone" }, { "type": "fluid_stack", "amount": 100, "fluid": "minecraft:lava" }], "results": [{ "id": "create_d2d:dolomite" }] })
    //Breccia
    e.custom({ "type": "create:compacting", "ingredients": [{ "item": "minecraft:granite" }, { "item": "minecraft:terracotta" }, { "type": "fluid_stack", "amount": 100, "fluid": "minecraft:lava" }], "results": [{ "id": "create_d2d:breccia" }] })
    //Gilded Blackstone
    e.custom({ "type": "create:compacting", "ingredients": [{ "item": "minecraft:blackstone" }, { "item": "minecraft:gold_nugget" }, { "item": "minecraft:gold_nugget" }, { "item": "minecraft:gold_nugget" }, { "item": "minecraft:gold_nugget" }, { "item": "minecraft:gold_nugget" }, { "item": "minecraft:gold_nugget" }, { "item": "minecraft:gold_nugget" }, { "item": "minecraft:gold_nugget" }], "results": [{ "id": "minecraft:gilded_blackstone" }] })
    //Lapis Lazuli
    e.custom({ "type": "create:compacting", "ingredients": [{ "item": "minecraft:amethyst_shard" }, { "item": "create:experience_nugget" }, { "item": "create:experience_nugget" }, { "item": "create:experience_nugget" }, { "item": "create:experience_nugget" }], "results": [{ "id": "minecraft:lapis_lazuli" }] })
    //Steel
    e.custom({ "type": "create:compacting", "heat_requirement": "superheated", "ingredients": [{ "item": "minecraft:iron_ingot" }, { "item": "minecraft:charcoal" }], "results": [{ "id": "mapperbase:pig_iron_chunk" }] })
})