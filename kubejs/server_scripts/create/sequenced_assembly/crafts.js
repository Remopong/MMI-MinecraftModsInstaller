ServerEvents.recipes(e => {
    // Dragon Egg
    e.recipes.create.sequenced_assembly([
        'minecraft:dragon_egg'
    ], 'minecraft:sniffer_egg', [
        e.recipes.create.filling('kubejs:incomplete_dragon_egg', [
            'kubejs:incomplete_dragon_egg',
            Fluid.of('create_dragons_plus:dragons_breath', 250)
        ])
    ]).transitionalItem('kubejs:incomplete_dragon_egg').loops(16)

    // Ominous Bottle
    e.recipes.create.sequenced_assembly([
        'minecraft:ominous_bottle'
    ], 'kubejs:empty_ominous_bottle', [
        e.recipes.create.deploying('kubejs:incomplete_ominous_bottle', ['kubejs:incomplete_ominous_bottle', 'minecraft:rotten_flesh']),
        e.recipes.create.deploying('kubejs:incomplete_ominous_bottle', ['kubejs:incomplete_ominous_bottle', 'minecraft:bone']),
        e.recipes.create.deploying('kubejs:incomplete_ominous_bottle', ['kubejs:incomplete_ominous_bottle', 'minecraft:spider_eye']),
        e.recipes.create.deploying('kubejs:incomplete_ominous_bottle', ['kubejs:incomplete_ominous_bottle', 'minecraft:gunpowder'])
    ]).transitionalItem('kubejs:incomplete_ominous_bottle').loops(1)

    // Pale Oak Heart
    if (Fluid.exists('create_confectionery:caramel')) {
        e.recipes.create.sequenced_assembly([
            'kubejs:pale_oak_heart'
        ], 'minecraft:pale_oak_log', [
            e.recipes.create.filling('kubejs:incomplete_pale_oak_heart', [
                'kubejs:incomplete_pale_oak_heart',
                Fluid.of('create_confectionery:caramel', 250)
            ]),
            e.recipes.create.deploying('kubejs:incomplete_pale_oak_heart', ['kubejs:incomplete_pale_oak_heart', '#minecraft:axes'])
        ]).transitionalItem('kubejs:incomplete_pale_oak_heart').loops(8)
    }

    // Raw Steel
    if (Item.exists('mapperbase:pig_iron_chunk') && Item.exists('mapperbase:raw_steel')) {
        e.recipes.create.sequenced_assembly([
            'mapperbase:raw_steel'
        ], 'mapperbase:pig_iron_chunk', [
            e.recipes.create.pressing('mapperbase:pig_iron_chunk', 'mapperbase:pig_iron_chunk'),
            e.recipes.create.deploying('mapperbase:pig_iron_chunk', ['mapperbase:pig_iron_chunk', 'mapperbase:pig_iron_chunk']),
            e.recipes.create.pressing('mapperbase:pig_iron_chunk', 'mapperbase:pig_iron_chunk'),
            e.recipes.create.deploying('mapperbase:pig_iron_chunk', ['mapperbase:pig_iron_chunk', 'mapperbase:pig_iron_chunk']),
            e.recipes.create.pressing('mapperbase:pig_iron_chunk', 'mapperbase:pig_iron_chunk')
        ]).transitionalItem('mapperbase:pig_iron_chunk').loops(1)
    }
})