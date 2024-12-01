shader_type canvas_item;
    
    uniform float progress : hint_range(0., 1.) = 1.;
    uniform float pixelFactor : hint_range(0,1) = .25;
    uniform vec4 ring_color : source_color = vec4(0.122, 0.478, 0.549, 1.0);
    uniform vec4 bg_color : source_color = vec4(0.612, 0.710, 0.812, 0.5);
    uniform vec4 bg_line_color : source_color = vec4(0.5,0.5,0.5,1);
    uniform vec4 empty_cell_color : source_color = vec4(0.25,0.25,0.25,1);
    uniform bool antialias = false;
    uniform float radius : hint_range(0, 1) = 0.7;
    uniform float line_width : hint_range(0, 1) = 0.21;
    uniform float bg_width : hint_range(0, 1) = 0.28;
    uniform float start_angle : hint_range(0., 360.) = 0.;
    uniform float segment_spacing : hint_range(0., 1.) = 0.05;
    uniform int segment_count = 3;
    
    mat2 tex_rotate(float _angle){
        return mat2(vec2(cos(_angle), -sin(_angle)), vec2(sin(_angle), cos(_angle)));
    }
    
    void fragment(){
        vec2 uv;
        if(pixelFactor != 0.){
            vec2 pixelNumber = vec2(textureSize(TEXTURE, 0)) * pixelFactor;
            vec2 pixelated_UV = round(UV * pixelNumber) / pixelNumber;
            uv = (pixelated_UV * 2.0 - 1.0) * tex_rotate((-radians(start_angle)));
        }else{
            uv = (UV * 2.0 - 1.0) * tex_rotate((-radians(start_angle)));
        }
        
        float removed_segments = 1.0 - progress;
        float angle = atan(uv.x, uv.y) + PI;
        float segment_size = (2. * PI) / float(segment_count);
        float segment = abs(sin(mod(angle + PI * 2. * 0. + segment_size / 2., segment_size) - segment_size / 2.)) * length(uv) - segment_spacing;
        angle -= removed_segments * 2. * PI;
        float circle = length(uv) - radius;
        float ring = abs(circle) - line_width;
        float background = abs(circle) - bg_width;
        
        if(!antialias){
            ring = ceil(ring);
            angle = ceil(angle);
            segment = ceil(segment);
            background = ceil(background);
        }
        
        ring = 1. - ring;
        segment = 1. - segment;
        background = 1. - background;
        
        ring = clamp(ring,0,1);
        angle = clamp(angle,0,1);
        segment = clamp(segment,0,1);
        background = clamp(background,0,1);
        float base_ring = ring;
        
        ring -= angle;
        if(segment_count >= 2) ring -= segment;
        ring = clamp(ring,0,1);
        
        if(ring > 0.){
            COLOR = ring_color;
            COLOR.a = ring;
        }else{
            if(segment >= 1. && base_ring >= 1.){
                COLOR = bg_line_color;
            }else if(base_ring >= 1.){
                COLOR = empty_cell_color;
            }else{
                COLOR = bg_color;
            }
            COLOR.a = background;
        }
    }