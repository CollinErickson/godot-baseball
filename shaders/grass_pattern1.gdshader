// Tells Godot this is a 3D shader that interacts with lighting.
shader_type spatial;

// These are variables you can edit directly in the Inspector!
uniform vec4 light_grass_color : source_color = vec4(0.2, 0.6, 0.1, 1.0);
uniform vec4 dark_grass_color : source_color = vec4(0.15, 0.5, 0.08, 1.0);
uniform float stripe_width : hint_range(0.1, 50.0) = 5.0;
uniform bool vertical_stripes = false;


varying vec3 world_position;

void vertex()
{
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Determine which world axis to use for the stripes.
    // WORLD_POSITION is the position of the pixel in 3D space.
    float axis_pos = vertical_stripes ? world_position.x : world_position.z;

    // This is the core logic for the alternating pattern.
    // 1. Divide the position by the stripe width to get a "stripe number".
    // 2. Use floor() to get a whole number for the current stripe.
    // 3. Use mod(..., 2.0) to see if that number is even or odd. It will result in 0.0 or 1.0.
    float stripe_check = mod(floor(axis_pos / stripe_width), 2.0);

    // If the stripe_check is 0.0, use the light color. Otherwise, use the dark color.
    if (stripe_check < 0.5) {
        ALBEDO = light_grass_color.rgb;
    } else {
        ALBEDO = dark_grass_color.rgb;
    }
}
