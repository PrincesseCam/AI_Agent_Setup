-- Create content_videos table for managing video content
CREATE TABLE IF NOT EXISTS content_videos (
    id SERIAL PRIMARY KEY,
    content_id VARCHAR(100) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    file_path VARCHAR(500),
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Publishing status tracking for each platform
    youtube_status VARCHAR(50) DEFAULT 'not_started',
    instagram_status VARCHAR(50) DEFAULT 'not_started',
    tiktok_status VARCHAR(50) DEFAULT 'not_started',
    twitter_status VARCHAR(50) DEFAULT 'not_started',
    facebook_status VARCHAR(50) DEFAULT 'not_started',
    threads_status VARCHAR(50) DEFAULT 'not_started',
    
    -- Store additional metadata as JSON
    metadata JSONB,
    
    -- Add timestamps
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on content_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_content_videos_content_id ON content_videos(content_id);

-- Create index on statuses for filtering
CREATE INDEX IF NOT EXISTS idx_youtube_status ON content_videos(youtube_status);
CREATE INDEX IF NOT EXISTS idx_instagram_status ON content_videos(instagram_status);
CREATE INDEX IF NOT EXISTS idx_tiktok_status ON content_videos(tiktok_status);
CREATE INDEX IF NOT EXISTS idx_twitter_status ON content_videos(twitter_status);

-- Create a view for content that needs publishing
CREATE OR REPLACE VIEW content_for_publishing AS
SELECT 
    content_id,
    title,
    file_path,
    creation_date,
    youtube_status,
    instagram_status,
    tiktok_status,
    twitter_status,
    facebook_status,
    threads_status
FROM 
    content_videos
WHERE
    youtube_status = 'for publishing' OR
    instagram_status = 'for publishing' OR
    tiktok_status = 'for publishing' OR
    twitter_status = 'for publishing' OR
    facebook_status = 'for publishing' OR
    threads_status = 'for publishing';

-- Create a view for publishing statistics
CREATE OR REPLACE VIEW publishing_stats AS
SELECT
    COUNT(*) AS total_videos,
    COUNT(CASE WHEN youtube_status = 'published' THEN 1 END) AS published_youtube,
    COUNT(CASE WHEN instagram_status = 'published' THEN 1 END) AS published_instagram,
    COUNT(CASE WHEN tiktok_status = 'published' THEN 1 END) AS published_tiktok,
    COUNT(CASE WHEN twitter_status = 'published' THEN 1 END) AS published_twitter,
    COUNT(CASE WHEN facebook_status = 'published' THEN 1 END) AS published_facebook,
    COUNT(CASE WHEN threads_status = 'published' THEN 1 END) AS published_threads,
    COUNT(CASE WHEN youtube_status = 'for publishing' THEN 1 END) AS pending_youtube,
    COUNT(CASE WHEN instagram_status = 'for publishing' THEN 1 END) AS pending_instagram,
    COUNT(CASE WHEN tiktok_status = 'for publishing' THEN 1 END) AS pending_tiktok,
    COUNT(CASE WHEN twitter_status = 'for publishing' THEN 1 END) AS pending_twitter,
    COUNT(CASE WHEN facebook_status = 'for publishing' THEN 1 END) AS pending_facebook,
    COUNT(CASE WHEN threads_status = 'for publishing' THEN 1 END) AS pending_threads
FROM 
    content_videos;

-- Sample queries
-- Find content waiting to be published
-- SELECT * FROM content_for_publishing;

-- Get publishing statistics
-- SELECT * FROM publishing_stats;

-- Find all content published successfully to YouTube
-- SELECT content_id, title, creation_date FROM content_videos WHERE youtube_status = 'published';

-- Find content that failed to publish on any platform
-- SELECT content_id, title FROM content_videos WHERE 
--   youtube_status = 'failed' OR
--   instagram_status = 'failed' OR
--   tiktok_status = 'failed' OR
--   twitter_status = 'failed';