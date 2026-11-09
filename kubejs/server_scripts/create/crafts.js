ServerEvents.recipes(event => {
    // Only attempt to add these recipes if the item actually exists in the game registry
    if (Item.exists('create_d2d:propeller')) {
        event.shaped('create_d2d:propeller', [
            ' B ',
            'BAB',
            ' B '
        ], {
            A: 'create:propeller',
            B: 'create:iron_sheet'
        });

        const colors = [
            'red', 'orange', 'yellow', 'lime', 'green', 'cyan',
            'light_blue', 'blue', 'purple', 'magenta', 'pink',
            'white', 'light_gray', 'gray', 'black', 'brown'
        ];

        colors.forEach(color => {
            let propellerId = `create_d2d:${color}_propeller`;
            if (Item.exists(propellerId)) {
                event.shapeless(propellerId, ['create_d2d:propeller', `minecraft:${color}_dye`]);
            }
        });
    }
});