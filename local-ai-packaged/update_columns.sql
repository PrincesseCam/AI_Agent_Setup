-- Add missing columns if they don't exist
DO $$
BEGIN
    -- Check if twitter_status column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'content_videos' AND column_name = 'twitter_status'
    ) THEN
        ALTER TABLE content_videos ADD COLUMN twitter_status VARCHAR(50) DEFAULT 'not_started';
    END IF;

    -- Check if threads_status column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'content_videos' AND column_name = 'threads_status'
    ) THEN
        ALTER TABLE content_videos ADD COLUMN threads_status VARCHAR(50) DEFAULT 'not_started';
    END IF;

    -- Check if updated_at column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'content_videos' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE content_videos ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    END IF;
END
$$;

-- Create index on the new status column
CREATE INDEX IF NOT EXISTS idx_twitter_status ON content_videos(twitter_status);

-- Fix the views
DROP VIEW IF EXISTS content_for_publishing;
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
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'content_videos' AND column_name = 'threads_status'
    ) THEN threads_status ELSE NULL END as threads_status
FROM 
    content_videos
WHERE
    youtube_status = 'for publishing' OR
    instagram_status = 'for publishing' OR
    tiktok_status = 'for publishing' OR
    twitter_status = 'for publishing' OR
    facebook_status = 'for publishing' OR
    (EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'content_videos' AND column_name = 'threads_status'
    ) AND threads_status = 'for publishing');

-- Recreate the stats view with conditional column inclusion
DROP VIEW IF EXISTS publishing_stats;
CREATE OR REPLACE VIEW publishing_stats AS
SELECT
    COUNT(*) AS total_videos,
    COUNT(CASE WHEN youtube_status = 'published' THEN 1 END) AS published_youtube,
    COUNT(CASE WHEN instagram_status = 'published' THEN 1 END) AS published_instagram,
    COUNT(CASE WHEN tiktok_status = 'published' THEN 1 END) AS published_tiktok,
    COUNT(CASE WHEN twitter_status = 'published' THEN 1 END) AS published_twitter,
    COUNT(CASE WHEN facebook_status = 'published' THEN 1 END) AS published_facebook,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'content_videos' AND column_name = 'threads_status'
    ) THEN COUNT(CASE WHEN threads_status = 'published' THEN 1 END) ELSE NULL END AS published_threads,
    COUNT(CASE WHEN youtube_status = 'for publishing' THEN 1 END) AS pending_youtube,
    COUNT(CASE WHEN instagram_status = 'for publishing' THEN 1 END) AS pending_instagram,
    COUNT(CASE WHEN tiktok_status = 'for publishing' THEN 1 END) AS pending_tiktok,
    COUNT(CASE WHEN twitter_status = 'for publishing' THEN 1 END) AS pending_twitter,
    COUNT(CASE WHEN facebook_status = 'for publishing' THEN 1 END) AS pending_facebook,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'content_videos' AND column_name = 'threads_status'
    ) THEN COUNT(CASE WHEN threads_status = 'for publishing' THEN 1 END) ELSE NULL END AS pending_threads
FROM 
    content_videos;