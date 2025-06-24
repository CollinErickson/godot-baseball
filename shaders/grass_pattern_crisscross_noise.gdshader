// Tells Godot this is a 3D shader that interacts with lighting.
shader_type spatial;

// These are variables you can edit directly in the Inspector!
uniform vec4 light_grass_color : source_color = vec4(0.2, 0.6, 0.1, 1.0);
uniform vec4 dark_grass_color : source_color = vec4(0.15, 0.5, 0.08, 1.0);
uniform float stripe_width : hint_range(0.1, 50.0) = 5.0;

// For noise
// A third color for patches of slightly different grass (e.g., more yellow/dry)
uniform vec4 variation_color : source_color = vec4(0.25, 0.6, 0.05, 1.0);
// The noise texture we created. 'hint_default_white' prevents errors if it's unassigned.
uniform sampler2D noise_texture : source_color, hint_default_white;
// Controls how strong the noise effect is. 0.0 is no noise, 1.0 is full noise.
uniform float noise_strength : hint_range(0.0, 1.0) = 0.35;

varying vec3 world_position;

void vertex()
{
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Determine which world axis to use for the stripes.
    // WORLD_POSITION is the position of the pixel in 3D space.
    //float axis_pos = world_position.x + world_position.z;

	vec4 base_color;
    // This is the core logic for the alternating pattern.
    // 1. Divide the position by the stripe width to get a "stripe number".
    // 2. Use floor() to get a whole number for the current stripe.
    // 3. Use mod(..., 2.0) to see if that number is even or odd. It will result in 0.0 or 1.0.
    // Check both X and Z axes
    float stripe_check_x = mod(floor(world_position.x / stripe_width), 2.0);
    float stripe_check_z = mod(floor(world_position.z / stripe_width), 2.0);

    // If the stripe_check is 0.0, use the light color. Otherwise, use the dark color.
    if (mod(stripe_check_x + stripe_check_z, 2.0) < 0.5) {
        //ALBEDO = light_grass_color.rgb;
		base_color = light_grass_color;
    } else {
        //ALBEDO = dark_grass_color.rgb;
		base_color = dark_grass_color;
    }
	
	
    // --- Part 2: Apply the noise variation ---
    // We sample the noise texture using the world position as coordinates.
    // This ensures the noise pattern covers the entire field without repeating like a tile.
    // We divide by a number (e.g., 50.0) to scale the noise pattern.
    float noise_value = texture(noise_texture, world_position.xz / 50.0).r;
    
    // The mix() function blends between two values.
    // When noise_value is 0, we get 100% base_color.
    // When noise_value is 1, we get 100% variation_color.
    // We multiply by noise_strength to control the overall intensity.
    vec3 final_color = mix(base_color.rgb, variation_color.rgb, noise_value * noise_strength);

    // --- Part 3: Set the final pixel color ---
    ALBEDO = final_color;

    // Make the noisier parts less shiny for extra realism
    ROUGHNESS = 0.5 + noise_value * 0.4;
	
}
