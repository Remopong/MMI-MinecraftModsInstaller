// Réécrit en JSON brut (format Create 6) : la méthode .transitionalItem() n'existe pas
// avec KubeJS 7 sans addon "KubeJS Create", ce qui faisait échouer tout le fichier.
ServerEvents.recipes(e => {
    const item = id => ({ item: id })
    const fluid = (id, amount) => ({ type: 'neoforge:single', fluid: id, amount: amount })
    const step = (type, transitional, extra) => ({
        type: type,
        ingredients: [item(transitional)].concat(extra || []),
        results: [{ id: transitional }]
    })
    const seq = (id, input, result, transitional, loops, sequence) => e.custom({
        type: 'create:sequenced_assembly',
        ingredient: input,
        loops: loops,
        results: [{ id: result }],
        sequence: sequence,
        transitional_item: { id: transitional }
    }).id(id)

    // Dragon Egg
    if (Fluid.exists('create_dragons_plus:dragons_breath')) {
        seq('kubejs:sequenced_assembly/dragon_egg', item('minecraft:sniffer_egg'), 'minecraft:dragon_egg',
            'kubejs:incomplete_dragon_egg', 16, [
                step('create:filling', 'kubejs:incomplete_dragon_egg', [fluid('create_dragons_plus:dragons_breath', 250)])
            ])
    }

    // Ominous Bottle
    seq('kubejs:sequenced_assembly/ominous_bottle', item('kubejs:empty_ominous_bottle'), 'minecraft:ominous_bottle',
        'kubejs:incomplete_ominous_bottle', 1, [
            step('create:deploying', 'kubejs:incomplete_ominous_bottle', [item('minecraft:rotten_flesh')]),
            step('create:deploying', 'kubejs:incomplete_ominous_bottle', [item('minecraft:bone')]),
            step('create:deploying', 'kubejs:incomplete_ominous_bottle', [item('minecraft:spider_eye')]),
            step('create:deploying', 'kubejs:incomplete_ominous_bottle', [item('minecraft:gunpowder')])
        ])

    // Pale Oak Heart (seulement si create_confectionery est installé)
    if (Fluid.exists('create_confectionery:caramel') && Item.exists('kubejs:incomplete_pale_oak_heart') && Item.exists('minecraft:pale_oak_log')) {
        seq('kubejs:sequenced_assembly/pale_oak_heart', item('minecraft:pale_oak_log'), 'kubejs:pale_oak_heart',
            'kubejs:incomplete_pale_oak_heart', 8, [
                step('create:filling', 'kubejs:incomplete_pale_oak_heart', [fluid('create_confectionery:caramel', 250)]),
                Object.assign(step('create:deploying', 'kubejs:incomplete_pale_oak_heart', [{ tag: 'minecraft:axes' }]), { keep_held_item: true })
            ])
    }

    // Raw Steel
    if (Item.exists('mapperbase:pig_iron_chunk') && Item.exists('mapperbase:raw_steel')) {
        const t = 'mapperbase:pig_iron_chunk'
        seq('kubejs:sequenced_assembly/raw_steel', item(t), 'mapperbase:raw_steel', t, 1, [
            step('create:pressing', t),
            step('create:deploying', t, [item(t)]),
            step('create:pressing', t),
            step('create:deploying', t, [item(t)]),
            step('create:pressing', t)
        ])
    }
})
