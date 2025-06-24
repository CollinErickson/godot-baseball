// Tells Godot this is a 3D shader that interacts with lighting.
shader_type spatial;

// These are variables you can edit directly in the Inspector!
uniform vec4 light_grass_color : source_color = vec4(0.2, 0.6, 0.1, 1.0);
uniform vec4 dark_grass_color : source_color = vec4(0.15, 0.5, 0.08, 1.0);
uniform float stripe_width : hint_range(0.1, 50.0) = 5.0;

varying vec3 world_position;

void vertex()
{
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Determine which world axis to use for the stripes.
    // WORLD_POSITION is the position of the pixel in 3D space.
    //float axis_pos = world_position.x + world_position.z;



    // This is the core logic for the alternating pattern.
    // 1. Divide the position by the stripe width to get a "stripe number".
    // 2. Use floor() to get a whole number for the current stripe.
    // 3. Use mod(..., 2.0) to see if that number is even or odd. It will result in 0.0 or 1.0.
    // Check both X and Z axes
    //float stripe_check_z = mod(floor(WORLD_POSITION.z / stripe_width), 2.0);
    //float stripe_check_x = mod(floor(WORLD_POSITION.x / stripe_width), 2.0);
    float stripe_check_x = mod(floor(world_position.x / stripe_width), 2.0);
    float stripe_check_z = mod(floor(world_position.z / stripe_width), 2.0);


    // If the stripe_check is 0.0, use the light color. Otherwise, use the dark color.
    if (mod(stripe_check_x + stripe_check_z, 2.0) < 0.5) {
        ALBEDO = light_grass_color.rgb;
    } else {
        ALBEDO = dark_grass_color.rgb;
    }
}
