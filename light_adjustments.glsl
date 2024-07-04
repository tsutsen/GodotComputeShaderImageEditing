#[compute]
#version 450

// set the number of invocations
layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

// declare shader parameters
// we do not need to rewrite them here so the variable is readonly
layout(set = 0, binding = 0, std430) readonly buffer custom_parameters {
	float brightness;
	float contrast;
} parameters;


// declare texture inputs
// the format should match the one we specified in the Godot script
layout(set = 0, binding = 1, rgba32f) readonly uniform image2D input_texture;
layout(set = 0, binding = 2, rgba32f) writeonly restrict uniform image2D output_texture;


// function to change brightness and contrast
vec4 brightnessContrast( vec4 value, float brightness, float contrast ) { 
	return vec4((value.rgb - 0.5) * (contrast + 1) + 0.5 + brightness, value.a); 
}

void main() {
	// get texel coordinates	
	ivec2 texel_coords = ivec2(gl_GlobalInvocationID.xy);

	// read pixels from the input texture
	vec4 texel = imageLoad(input_texture, texel_coords);

  	// apply the function to the texel
	texel = brightnessContrast(texel,parameters.brightness,parameters.contrast);

	// write modified pixels to output texture
	imageStore(output_texture, texel_coords, texel);
}