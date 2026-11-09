ServerEvents.recipes(e => {

    //Calcite
    e.custom({ "type": "create_mechanical_extruder:extruding", "blockIngredients": { "first": { "blocks": "minecraft:powder_snow" }, "second": { "blocks": "minecraft:water" } }, "consumeBlocks": { "first": false, "second": false }, "result": { "id": "minecraft:calcite" } })
    //Dripstone
    e.custom({ "type": "create_mechanical_extruder:extruding", "blockIngredients": { "first": { "blocks": "create:chocolate" }, "second": { "blocks": "minecraft:lava" } }, "consumeBlocks": { "first": false, "second": false }, "result": { "id": "minecraft:dripstone_block" } })
    //Deepslate
    e.custom({ "type": "create_mechanical_extruder:extruding", "blockIngredients": { "first": { "blocks": "minecraft:water" }, "second": { "blocks": "minecraft:lava" } }, "catalyst": { "blocks": "minecraft:bedrock" }, "consumeBlocks": { "first": false, "second": false }, "result": { "id": "minecraft:cobbled_deepslate" } })
    //Larvikite
    e.custom({ "type": "create_mechanical_extruder:extruding", "blockIngredients": { "first": { "blocks": "kubejs:light_blue" }, "second": { "blocks": "minecraft:lava" } }, "consumeBlocks": { "first": false, "second": false }, "result": { "id": "embellishcraft:larvikite" } })
    //Slate
    e.custom({ "type": "create_mechanical_extruder:extruding", "blockIngredients": { "first": { "blocks": "kubejs:blue" }, "second": { "blocks": "minecraft:lava" } }, "consumeBlocks": { "first": false, "second": false }, "result": { "id": "embellishcraft:slate" } })
    //Jade
    e.custom({ "type": "create_mechanical_extruder:extruding", "blockIngredients": { "first": { "blocks": "create_mechanical_chicken:chicken_nutrient" }, "second": { "blocks": "minecraft:lava" } }, "consumeBlocks": { "first": false, "second": false }, "result": { "id": "embellishcraft:jade" } })
    //Marble
    e.custom({ "type": "create_mechanical_extruder:extruding", "blockIngredients": { "first": { "blocks": "kubejs:white" }, "second": { "blocks": "minecraft:lava" } }, "consumeBlocks": { "first": false, "second": false }, "result": { "id": "embellishcraft:marble" } })
    //Gneiss
    ServerEvents.recipes(event => {
        event.recipes.create_mechanical_extruder.extruding('embellishcraft:gneiss', [
            Block.id('create_confectionery:white_chocolate').blockStates,
            Block.id('minecraft:lava').blockStates
        ]);
    });
    //Basalt
    e.custom({ "type": "create_mechanical_extruder:extruding", "blockIngredients": { "first": { "blocks": "kubejs:black" }, "second": { "blocks": "minecraft:lava" } }, "consumeBlocks": { "first": false, "second": false }, "result": { "id": "embellishcraft:basalt" } })

})