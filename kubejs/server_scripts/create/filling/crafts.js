ServerEvents.recipes(event => {
    const colors = [
        'lime', 'pink', 'blue', 'white', 'orange', 'cyan',
        'gray', 'purple', 'brown', 'light_blue', 'green', 'red',
        'magenta', 'yellow', 'light_gray', 'black'
    ];

    // Safe asphalt & bore block filling loop
    colors.forEach(color => {
        let asphalt = `create_d2d:${color}_asphalt`;
        let boreBlock = `create_d2d:${color}_bore_block`;

        if (Item.exists('create_d2d:asphalt') && Item.exists(asphalt)) {
            event.recipes.create.filling(asphalt, [
                'create_d2d:asphalt',
                Fluid.of(`kubejs:${color}`, 50)
            ]);
        }

        if (Item.exists('create_d2d:bore_block') && Item.exists(boreBlock)) {
            event.recipes.create.filling(boreBlock, [
                'create_d2d:bore_block',
                Fluid.of(`kubejs:${color}`, 50)
            ]);
        }
    });

    // Fix caramel filling syntax & check if caramel fluid exists
    if (Fluid.exists('create_confectionery:caramel')) {
        event.recipes.create.filling('kubejs:pale_oak_heart', [
            'kubejs:empty_pale_oak_heart',
            Fluid.of('create_confectionery:caramel', 250)
        ]);
    }
});