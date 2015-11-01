#version 430

#pragma include "Includes/Configuration.inc.glsl"
#pragma include "Includes/ImportanceSampling.inc.glsl"

#pragma optionNV (unroll all)

in vec2 texcoord;
out vec4 result;

uniform int current_mip;
uniform samplerCube SourceMipmap;
uniform writeonly imageCube DestMipmap;


#define USE_IMPORTANCE_SAMPLING 1


void main() {

    // Get cubemap coordinate
    int texsize = imageSize(DestMipmap).x;
    ivec2 coord = ivec2(gl_FragCoord.xy);

    ivec2 clamped_coord; int face;
    vec3 n = texcoord_to_cubemap(texsize, coord, clamped_coord, face);

    float sample_size = 0.1 + current_mip * 0.15;

    vec3 accum = vec3(0);
    
    #if USE_IMPORTANCE_SAMPLING

        // -------- Importance Sampling ----------

        const int num_samples = 64;

        for (int i = 0; i < num_samples; ++i) {
            vec2 Xi = Hammersley(i, num_samples);
            vec3 Li = ImportanceSampleGGX(Xi, sample_size, n);

            float weight = max(0.0, dot(n, Li));
            vec3 fval = textureLod(SourceMipmap, Li, current_mip).xyz;
            accum += fval * weight;
        }

        accum /= num_samples;

    #else


        // -------- Box Filter ----------
        // Does produce some artifacts when bright spots appear

        const int filter_size = 1;
        for (int x = -filter_size; x <= filter_size; ++x) {
            for (int y = -filter_size; y <= filter_size; ++y) {

                ivec2 offcoord = clamped_coord + ivec2(x, y) * 2;
                vec2 local_coord = ((offcoord+0.5) / float(texsize)) * 2.0 - 1.0;
                vec3 sample_dir = get_cubemap_coordinate(face, local_coord);

                accum += textureLod(SourceMipmap, sample_dir, current_mip).xyz;
            }
        }

        float effective_filter_width = 2 * filter_size + 1;
        accum /= effective_filter_width * effective_filter_width;

    #endif

    result.xyz = accum;
    result.w = 1.0;

    imageStore(DestMipmap, ivec3(clamped_coord, face), vec4(accum, 1.0));
}