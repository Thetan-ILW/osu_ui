local shaders = {}

shaders.lighten = love.graphics.newShader([[
	extern Image tex;
	extern float amount;
	vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
	{
	    vec4 texturecolor = Texel(tex, texture_coords);
	    return vec4(texturecolor.rgb + amount, texturecolor.a) * color;
	}
]])

return shaders
