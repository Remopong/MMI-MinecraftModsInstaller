ServerEvents.recipes(event => {
    if (Item.exists('create_aquatic_ambitions:polished_quartz_tine') && Item.exists('create_aquatic_ambitions:prismarine_rod')) {
        event.recipes.create.mechanical_crafting('minecraft:trident', [
            ' AA',
            ' BA',
            'B  '
        ], {
            A: 'create_aquatic_ambitions:polished_quartz_tine',
            B: 'create_aquatic_ambitions:prismarine_rod'
        });
    }
});