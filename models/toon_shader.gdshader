shader_type spatial;

uniform vec3 albedo : source_color = vec3(1.0);
uniform int shading_levels : hint_range(1,10) = 3;
// might want to experiment with outlines later
//uniform float outline_width : hint_range(0.0, 0.1) = 0.02;
//uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

//void vertex() {
	//// Called for every vertex the material is visible on.
//}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = albedo;
}

void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
	float NdotL = dot(NORMAL, LIGHT);
	
	// step the shading
	float level = floor(NdotL * float(shading_levels)) / float(shading_levels);
	level = max(level, 0.0);
	
	DIFFUSE_LIGHT +=  ALBEDO * LIGHT_COLOR * level * ATTENUATION;
}
