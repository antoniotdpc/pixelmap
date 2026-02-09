-- PixelMap Database Schema
-- PostGIS enabled for geospatial operations

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    username TEXT UNIQUE,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User settings
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    fog_of_war_enabled BOOLEAN DEFAULT TRUE,
    fog_reveal_radius DOUBLE PRECISION DEFAULT 50.0,
    default_zoom_level INTEGER DEFAULT 2,
    track_location BOOLEAN DEFAULT TRUE,
    sync_to_cloud BOOLEAN DEFAULT TRUE,
    map_style TEXT DEFAULT 'minecraft',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- User stats
CREATE TABLE IF NOT EXISTS public.user_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    total_distance_meters INTEGER DEFAULT 0,
    explored_tiles INTEGER DEFAULT 0,
    unique_locations INTEGER DEFAULT 0,
    days_active INTEGER DEFAULT 0,
    first_explored_at TIMESTAMP WITH TIME ZONE,
    last_explored_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- User locations (GPS track points)
CREATE TABLE IF NOT EXISTS public.user_locations (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    altitude DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Geospatial index
    geom GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
    ) STORED
);

-- Explored areas (fog of war polygons)
CREATE TABLE IF NOT EXISTS public.explored_areas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    tile_key TEXT NOT NULL,
    zoom_level INTEGER NOT NULL,
    min_lat DOUBLE PRECISION NOT NULL,
    max_lat DOUBLE PRECISION NOT NULL,
    min_lng DOUBLE PRECISION NOT NULL,
    max_lng DOUBLE PRECISION NOT NULL,
    explored_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accuracy DOUBLE PRECISION,
    
    -- Geospatial data
    geom GEOMETRY(POLYGON, 4326),
    
    UNIQUE(user_id, tile_key)
);

-- Tile cache for processed pixelated tiles
CREATE TABLE IF NOT EXISTS public.tile_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tile_key TEXT UNIQUE NOT NULL,
    x INTEGER NOT NULL,
    y INTEGER NOT NULL,
    z INTEGER NOT NULL,
    pixelated_data TEXT, -- Base64 encoded image
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Track segments (batch uploaded GPS tracks)
CREATE TABLE IF NOT EXISTS public.track_segments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    distance_meters INTEGER,
    point_count INTEGER,
    processed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Geospatial track
    geom GEOMETRY(LINESTRING, 4326)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_locations_user_id ON public.user_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_locations_recorded_at ON public.user_locations(recorded_at);
CREATE INDEX IF NOT EXISTS idx_user_locations_geom ON public.user_locations USING GIST(geom);

CREATE INDEX IF NOT EXISTS idx_explored_areas_user_id ON public.explored_areas(user_id);
CREATE INDEX IF NOT EXISTS idx_explored_areas_tile_key ON public.explored_areas(tile_key);
CREATE INDEX IF NOT EXISTS idx_explored_areas_zoom ON public.explored_areas(zoom_level);
CREATE INDEX IF NOT EXISTS idx_explored_areas_geom ON public.explored_areas USING GIST(geom);
CREATE INDEX IF NOT EXISTS idx_explored_areas_bounds ON public.explored_areas(min_lat, max_lat, min_lng, max_lng);

CREATE INDEX IF NOT EXISTS idx_track_segments_user_id ON public.track_segments(user_id);
CREATE INDEX IF NOT EXISTS idx_track_segments_geom ON public.track_segments USING GIST(geom);

-- Functions

-- Process track segment and update explored areas
CREATE OR REPLACE FUNCTION process_track_segment(
    p_user_id UUID,
    p_track_geojson TEXT
)
RETURNS VOID AS $$
DECLARE
    v_track_geom GEOMETRY;
    v_buffer_distance DOUBLE PRECISION;
    v_radius DOUBLE PRECISION;
BEGIN
    -- Get user's fog reveal radius
    SELECT fog_reveal_radius INTO v_radius
    FROM public.user_settings
    WHERE user_id = p_user_id;
    
    v_radius := COALESCE(v_radius, 50.0);
    
    -- Convert GeoJSON to geometry
    v_track_geom := ST_GeomFromGeoJSON(p_track_geojson);
    
    -- Create buffer around track (explored area)
    v_buffer_distance := v_radius / 111320.0; -- Rough conversion to degrees
    
    -- Insert explored area for each tile touched by the track
    INSERT INTO public.explored_areas (
        user_id, tile_key, zoom_level, 
        min_lat, max_lat, min_lng, max_lng,
        geom
    )
    SELECT 
        p_user_id,
        format('%s/%s/%s', z, x, y) as tile_key,
        z as zoom_level,
        ST_YMin(tile_geom) as min_lat,
        ST_YMax(tile_geom) as max_lat,
        ST_XMin(tile_geom) as min_lng,
        ST_XMax(tile_geom) as max_lng,
        tile_geom as geom
    FROM (
        SELECT 
            generate_series(0, 19) as z,
            (ST_XMin(expanded_bbox)::int) as x_start,
            (ST_XMax(expanded_bbox)::int) as x_end,
            (ST_YMin(expanded_bbox)::int) as y_start,
            (ST_YMax(expanded_bbox)::int) as y_end
        FROM (
            SELECT ST_Expand(ST_Envelope(v_track_geom), v_buffer_distance) as expanded_bbox
        ) bbox
        CROSS JOIN generate_series(0, 19) z
    ) tiles
    CROSS JOIN LATERAL (
        SELECT z as zoom, 
               generate_series(x_start, x_end) as x,
               generate_series(y_start, y_end) as y
    ) coords
    CROSS JOIN LATERAL (
        SELECT ST_TileEnvelope(zoom, x, y) as tile_geom
    ) envelope
    WHERE ST_Intersects(v_track_geom, tile_geom)
    ON CONFLICT (user_id, tile_key) DO NOTHING;
    
    -- Update user stats
    UPDATE public.user_stats
    SET 
        total_distance_meters = total_distance_meters + ST_Length(v_track_geom::geography)::int,
        last_explored_at = NOW(),
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Update unique locations count
    UPDATE public.user_stats
    SET unique_locations = (
        SELECT COUNT(DISTINCT tile_key) 
        FROM public.explored_areas 
        WHERE user_id = p_user_id
    )
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Check if location is explored
CREATE OR REPLACE FUNCTION is_location_explored(
    p_user_id UUID,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.explored_areas
        WHERE user_id = p_user_id
        AND min_lat <= p_latitude
        AND max_lat >= p_latitude
        AND min_lng <= p_longitude
        AND max_lng >= p_longitude
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql;

-- Get fog polygons for an area
CREATE OR REPLACE FUNCTION get_fog_polygons(
    p_user_id UUID,
    p_min_lat DOUBLE PRECISION,
    p_max_lat DOUBLE PRECISION,
    p_min_lng DOUBLE PRECISION,
    p_max_lng DOUBLE PRECISION
)
RETURNS TABLE (
    id UUID,
    tile_key TEXT,
    geom_geojson TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ea.id,
        ea.tile_key,
        ST_AsGeoJSON(ea.geom)::TEXT as geom_geojson
    FROM public.explored_areas ea
    WHERE ea.user_id = p_user_id
    AND ea.max_lat >= p_min_lat
    AND ea.min_lat <= p_max_lat
    AND ea.max_lng >= p_min_lng
    AND ea.min_lng <= p_max_lng;
END;
$$ LANGUAGE plpgsql;

-- Triggers

-- Update timestamp on user_settings update
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_settings_updated
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_user_stats_updated
    BEFORE UPDATE ON public.user_stats
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Row Level Security policies

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.explored_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tile_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.track_segments ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY "Users can view own data" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own settings" ON public.user_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own settings" ON public.user_settings
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own stats" ON public.user_stats
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own locations" ON public.user_locations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own locations" ON public.user_locations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own explored areas" ON public.explored_areas
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own explored areas" ON public.explored_areas
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own tracks" ON public.track_segments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tracks" ON public.track_segments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Tile cache is readable by all (processed tiles)
CREATE POLICY "Tile cache readable by all" ON public.tile_cache
    FOR SELECT USING (true);

-- Insert new user trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user record
    INSERT INTO public.users (id, email, created_at)
    VALUES (NEW.id, NEW.email, NOW());
    
    -- Create default settings
    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id);
    
    -- Create stats record
    INSERT INTO public.user_stats (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user record on auth signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
