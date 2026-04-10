player.onChat("clear", function () {
    for (let i = GROUND_POS; i < 100; i++) {
        blocks.fill(
            AIR,
            world(-8, i, -8),
            world(80, i, 80),
            FillOperation.Replace
        )
    }
    for (let j = GROUND_POS; j > 49; j--) {
        blocks.fill(
            SANDSTONE,
            world(-8, j, -8),
            world(80, j, 80),
            FillOperation.Replace
        )
    }
})

player.onChat("castle", function () {
    let internal_width = 40
    let internal_length = 60
    let width_center = internal_width / 2
    let length_center = internal_length / 2
    let foss_width = 3
    let wall_width = 3
    let edge_width = foss_width + wall_width
    let total_width = internal_width + (wall_width + foss_width) * 2
    let total_length = internal_length + (wall_width + foss_width) * 2
    let second_floor = GROUND_POS + 7

    for (let y = 0; y < 3; y++) {
        blocks.fill(
            WATER,
            world(-edge_width + 1, GROUND_POS - y, -edge_width + 1),
            world(internal_width + edge_width, GROUND_POS - y, internal_length + edge_width)
        )
    }

    //The First Floor
    for (let y = -2; y <= 1; y++) {
        blocks.fill(
            COBBLESTONE,
            world(-wall_width + 1, GROUND_POS + y, -wall_width + 1),
            world(internal_width + wall_width, GROUND_POS + y, internal_length + wall_width)
        )
    }

    //Floor
    blocks.fill(
        PLANKS_ACACIA,
        world(1, GROUND_POS, 1),
        world(internal_width, GROUND_POS, internal_length),
        FillOperation.Replace
    )

    for (let y = GROUND_POS + 2; y <= second_floor + 1; y++) {

        let random = randint(0, 1)
        let random_sandstone = random == 0 ? SMOOTH_SANDSTONE : CHISELED_SANDSTONE
        blocks.fill(
            random_sandstone,
            world(-wall_width + 1, y, -wall_width + 1),
            world(internal_width + wall_width, y, internal_length + wall_width)
        )
    }

    for (let y = GROUND_POS + 1; y <= second_floor + 1; y++) {
        blocks.fill(
            AIR,
            world(1, y, 1),
            world(internal_width, y, internal_length),
            FillOperation.Destroy
        )
    }

    //Teeth
    let step = 2
    let builder_pos = world(1 - wall_width, second_floor + 2, 1 - wall_width)
    for (let x = 1 - wall_width; x <= internal_width + wall_width; x += step) {
        blocks.place(SANDSTONE_STAIRS, builder_pos)
        builder_pos = builder_pos.move(CardinalDirection.East, step)
    }
    builder_pos = world(internal_width + wall_width, second_floor + 2, 1 - wall_width)
    for (let z = 1 - wall_width; z <= internal_length + wall_width; z += step) {
        blocks.place(SANDSTONE_STAIRS, builder_pos)
        builder_pos = builder_pos.move(CardinalDirection.South, step)
    }
    builder_pos = world(internal_width + wall_width, second_floor + 2, internal_length + wall_width)
    for (let x = internal_width + wall_width; x >= 1 - wall_width; x -= step) {
        blocks.place(SANDSTONE_STAIRS, builder_pos)
        builder_pos = builder_pos.move(CardinalDirection.West, step)
    }
    builder_pos = world(1 - wall_width, second_floor + 2, internal_length + wall_width)
    for (let z = internal_length + wall_width; z >= 1 - wall_width; z -= step) {
        blocks.place(SANDSTONE_STAIRS, builder_pos)
        builder_pos = builder_pos.move(CardinalDirection.North, step)
    }

    //Pillar
    blocks.fill(
        BROWN_TERRACOTTA,
        world(width_center, GROUND_POS + 1, length_center),
        world(width_center, GROUND_POS + 6, length_center),
        FillOperation.Replace
    )

    let pillar_top = world(width_center, second_floor - 1, length_center)
    builder_pos = pillar_top

    //Forward
    for (let index = 0; index < 3; index++) {
        builder_pos = positions.add(builder_pos, forward)
        blocks.place(OAK_FENCE, builder_pos)
    }
    blocks.place(GLOWSTONE, positions.add(builder_pos, down))
    builder_pos = pillar_top

    //Back
    for (let index = 0; index < 3; index++) {
        builder_pos = positions.add(builder_pos, back)
        blocks.place(OAK_FENCE, builder_pos)
    }
    blocks.place(GLOWSTONE, positions.add(builder_pos, down))
    builder_pos = pillar_top

    //Right
    for (let index = 0; index < 3; index++) {
        builder_pos = positions.add(builder_pos, right)
        blocks.place(OAK_FENCE, builder_pos)
    }
    blocks.place(GLOWSTONE, positions.add(builder_pos, down))
    builder_pos = pillar_top

    //Left
    for (let index = 0; index < 3; index++) {
        builder_pos = positions.add(builder_pos, left)
        blocks.place(OAK_FENCE, builder_pos)
    }
    blocks.place(GLOWSTONE, positions.add(builder_pos, down))

    //Gate
    blocks.fill(
        AIR,
        world(1 - wall_width, GROUND_POS + 1, length_center - 1),
        world(0, second_floor - 1, length_center + 1),
        FillOperation.Destroy
    )

    //Bridge
    blocks.fill(
        SMOOTH_RED_SANDSTONE_SLAB,
        world(1 - edge_width - 1, GROUND_POS + 1, length_center - 1),
        world(0, GROUND_POS + 1, length_center + 1),
        FillOperation.Replace
    )

    //Windows
    step = internal_length / 5
    for (let x = 1 - wall_width; x <= internal_width + wall_width; x += internal_width + wall_width) {
        for (let z = step; z <= internal_length - step; z += step) {
            if (z >= length_center - 3 && z <= length_center + 3) {
                continue
            }

            blocks.fill(
                AIR,
                world(x, GROUND_POS + 3, z),
                world(x + wall_width, GROUND_POS + 5, z + 2),
                FillOperation.Destroy
            )
            blocks.fill(
                IRON_BARS,
                world(x + 1, GROUND_POS + 3, z),
                world(x + 1, GROUND_POS + 5, z + 2),
                FillOperation.Replace
            )
        }
    }

    //Second floor
    blocks.fill(
        PLANKS_ACACIA,
        world(1, second_floor, 1),
        world(internal_width, second_floor, internal_length)
    )

    //Stairs to the second floor
    blocks.fill(
        AIR,
        world(width_center - 3, second_floor, length_center + 10),
        world(width_center + 2, second_floor, length_center + 13),
        FillOperation.Destroy
    )

    builder_pos = world(width_center + 3, second_floor, length_center + 10)
    for (let y = second_floor; y > GROUND_POS; y--) {
        builder_pos = world(
            builder_pos.getValue(Axis.X) - 1,
            y,
            length_center + 10
        )

        blocks.place(ACACIA_WOOD_STAIRS, builder_pos)
        for (let x = 0; x < 3; x++) {
            builder_pos = positions.add(builder_pos, forward)
            blocks.place(ACACIA_WOOD_STAIRS, builder_pos)
        }
    }

    //Towers
    for (let y = GROUND_POS - 2; y <= second_floor + 3; y++) {
        let radius: number = 3;
        let operation: ShapeOperation = ShapeOperation.Replace

        if(y > second_floor + 1) {
            radius = 4
            operation = ShapeOperation.Hollow
        }

        shapes.circle(
            CHISELED_RED_SANDSTONE,
            world(1 - wall_width, y, 1 - wall_width),
            radius,
            Axis.Y,
            operation
        )

        shapes.circle(
            CHISELED_RED_SANDSTONE,
            world(internal_width + wall_width, y, 1 - wall_width),
            radius,
            Axis.Y,
            operation
        )

        shapes.circle(
            CHISELED_RED_SANDSTONE,
            world(internal_width + wall_width, y, internal_length + wall_width),
            radius,
            Axis.Y,
            operation
        )

        shapes.circle(
            CHISELED_RED_SANDSTONE,
            world(1 - wall_width, y, internal_length + wall_width),
            radius,
            Axis.Y,
            operation
        )
    }
})

const GROUND_POS = 55
let forward = world(0, 0, 1)
let right = world(1, 0, 0)
let left = world(-1, 0, 0)
let back = world(0, 0, -1)
let up = world(0, 1, 0)
let down = world(0, -1, 0)