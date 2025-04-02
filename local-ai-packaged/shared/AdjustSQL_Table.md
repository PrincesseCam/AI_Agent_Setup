I see the issue. You're getting errors because the `twitter_status` column doesn't exist in your existing `content_videos` table. This happens when you try to apply the new script to an existing table that has a different schema.

Here's how to fix this:

## Option 1: Modify Just the Missing Columns

Let's create a script that only adds the missing columns to your existing table:

```sql
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
```

Save this as `update_columns.sql` and run it:

```bash
docker cp update_columns.sql local-ai-packaged-postgres-1:/tmp/update_columns.sql
docker exec -it local-ai-packaged-postgres-1 psql -U root -d n8n -f /tmp/update_columns.sql
```

## Option 2: See Your Current Schema

If you want to see what your current table looks like before making changes:

```bash
docker exec -it local-ai-packaged-postgres-1 psql -U root -d n8n -c "\d content_videos"
```

This will show you all the columns that currently exist in your table.

## Option 3: Drop and Recreate

If you don't have important data in the table yet, you could drop it and recreate:

```bash
docker exec -it local-ai-packaged-postgres-1 psql -U root -d n8n -c "DROP TABLE content_videos CASCADE;"
```

Then run the original setup script again.

## For the n8n Workflow

Make sure your workflow properly handles the case where the columns might not exist. In the database query, you can use the COALESCE function:

```sql
UPDATE content_videos SET
  youtube_status = '{{ $json.platformStatuses.youtube_status }}',
  instagram_status = '{{ $json.platformStatuses.instagram_status }}',
  tiktok_status = '{{ $json.platformStatuses.tiktok_status }}',
  twitter_status = '{{ $json.platformStatuses.twitter_status }}',
  metadata = '{{ JSON.stringify($json.publishingResults) }}'
WHERE content_id = '{{ $json.contentId }}'
```

Let me know which approach you'd prefer to take!