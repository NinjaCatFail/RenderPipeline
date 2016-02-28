/**
 *
 * RenderPipeline
 *
 * Copyright (c) 2014-2016 tobspr <tobias.springer1@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#version 420

#define USE_MAIN_SCENE_DATA
#pragma include "render_pipeline_base.inc.glsl"

// Tell the lighting pipeline we are doing this in screen space, so gl_FragCoord
// is available.
#define IS_SCREEN_SPACE 1

#pragma include "includes/light_culling.inc.glsl"
#pragma include "includes/transforms.inc.glsl"
#pragma include "includes/lighting_pipeline.inc.glsl"
#pragma include "includes/gbuffer.inc.glsl"

out vec4 result;

uniform GBufferData GBuffer;

void main() {

    // Extract material properties
    vec2 texcoord = get_texcoord();
    Material m = unpack_material(GBuffer);
    ivec3 tile = get_lc_cell_index(
        ivec2(gl_FragCoord.xy),
        distance(MainSceneData.camera_pos, m.position));

    // Don't shade pixels out of the shading range
    if (tile.z >= LC_TILE_SLICES) {
        result = vec4(0, 0, 0, 1);
        return;
    }

    // Apply all lights
    result.xyz = shade_material_from_tile_buffer(m, tile);
    result.w = 1.0;

    /*

    Various debugging modes for previewing materials

    */

    #if MODE_ACTIVE(DIFFUSE)
        result.xyz = vec3(m.basecolor);
    #endif

    #if MODE_ACTIVE(ROUGHNESS)
        result.xyz = vec3(m.roughness);
    #endif

    #if MODE_ACTIVE(SPECULAR)
        result.xyz = vec3(m.specular);
    #endif

    #if MODE_ACTIVE(NORMAL)
        result.xyz = vec3(m.normal);
    #endif

    #if MODE_ACTIVE(METALLIC)
        result.xyz = vec3(m.metallic);
    #endif

    #if MODE_ACTIVE(TRANSLUCENCY)
        result.xyz = vec3(m.translucency);
    #endif
}