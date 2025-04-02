# Windows Installation and Setup Guide for n8n Video Content Automation

This comprehensive guide walks you through setting up the complete video content automation system on a Windows environment with your NVIDIA 3050 8GB GPU.

## System Requirements

- Windows 10 or 11
- Docker Desktop for Windows with WSL 2 backend
- NVIDIA 3050 GPU with 8GB VRAM
- NVIDIA drivers (latest version)
- n8n Version 1.79.3 or newer
- At least 16GB RAM
- 100GB+ free disk space

## Initial Setup

### 1. Install Docker Desktop

1. Download Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop)
2. Install with WSL 2 backend
3. Enable NVIDIA GPU support in Docker:
   - Open Docker Desktop → Settings → Resources → NVIDIA GPU
   - Enable "Use the WSL 2 based engine"
   - Enable "Use GPU acceleration"

### 2. Configure Directory Structure

1. Create the base directory for all content:
   ```powershell
   New-Item -ItemType Directory -Force -Path "C:\data\shared"
   New-Item -ItemType Directory -Force -Path "C:\data\shared\configs"
   New-Item -ItemType Directory -Force -Path "C:\data\shared\templates"
   New-Item -ItemType Directory -Force -Path "C:\data\shared\logs"
   ```

2. Set appropriate permissions:
   ```powershell
   # Allow Docker containers to access the directory
   icacls "C:\data\shared" /grant "Users:(OI)(CI)F" /T
   ```

### 3. Prepare Docker Compose File

1. Create a file named `docker-compose.yml` in a suitable location
2. Copy the provided Docker Compose content (make sure paths use Windows format)
3. Configure environment variables:
   ```powershell
   # Create a .env file in the same directory as docker-compose.yml
   $envContent = @"
   POSTGRES_USER=n8n
   POSTGRES_PASSWORD=n8npassword
   POSTGRES_DB=n8n
   N8N_ENCRYPTION_KEY=your-random-encryption-key
   N8N_USER_MANAGEMENT_JWT_SECRET=your-random-jwt-secret
   "@
   
   Set-Content -Path ".\.env" -Value $envContent
   ```

### 4. Start Docker Services

```powershell
docker-compose up -d
```

This will start all the required containers: n8n, Postgres, FFmpeg with NVIDIA support, Qdrant, and other services defined in your compose file.

## Setting Up External Services

### 1. Stable Diffusion (AUTOMATIC1111)

1. Ensure your Stable Diffusion installation is accessible at http://localhost:7861
2. Verify the API is enabled (use the `--api` flag in your startup command)
3. Test the API connection:
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:7861/sdapi/v1/sd-models" -Method GET
   ```

### 2. Ollama Setup

1. Install Ollama for Windows from [ollama.ai](https://ollama.ai)
2. Pull required models:
   ```powershell
   ollama pull llama3.1
   ollama pull nomic-embed-text
   ```
3. Verify Ollama is running and accessible:
   ```powershell
   ollama list
   ```

### 3. ElevenLabs API

1. Create an account at [elevenlabs.io](https://elevenlabs.io)
2. Generate an API key from your profile settings
3. Create a voice and note its ID
4. Keep these details for later configuration in n8n

## Database Setup

1. Connect to Postgres and create the content database:
   ```powershell
   # Create SQL script
   $sqlScript = @"
   CREATE TABLE IF NOT EXISTS content_videos (
       id SERIAL PRIMARY KEY,
       content_id VARCHAR(50) UNIQUE NOT NULL,
       title VARCHAR(200) NOT NULL,
       niche VARCHAR(100) NOT NULL,
       creation_date TIMESTAMP NOT NULL DEFAULT NOW(),
       youtube_status VARCHAR(20),
       instagram_status VARCHAR(20),
       tiktok_status VARCHAR(20),
       facebook_status VARCHAR(20),
       file_path VARCHAR(500),
       metadata JSONB
   );
   "@
   
   # Write to file
   Set-Content -Path "C:\data\shared\configs\create_content_db.sql" -Value $sqlScript
   
   # Execute SQL script
   docker exec -i postgres psql -U n8n -d n8n -c "$(Get-Content -Path "C:\data\shared\configs\create_content_db.sql" -Raw)"
   ```

## Importing n8n Workflows

### 1. Access n8n

1. Open your browser and navigate to http://localhost:5678
2. Create an account or log in
3. Go to Settings → Credentials to set up required credentials

### 2. Set Up Credentials

Create the following credential sets:

1. **ElevenLabs API**:
   - Type: Generic API
   - Header Auth: `xi-api-key`: [Your API Key]

2. **Google API (for YouTube)**:
   - Set up OAuth2 credentials for YouTube API

3. **Instagram API**:
   - Set up OAuth2 credentials for Instagram Graph API

4. **TikTok API**:
   - Set up OAuth2 credentials for TikTok API

5. **Facebook Page API**:
   - Set up OAuth2 credentials for Facebook Graph API

6. **PostgreSQL**:
   - Host: postgres
   - Database: n8n
   - User: n8n
   - Password: [Your password from .env]

### 3. Import Workflows

Import each workflow file:

1. Go to Workflows → Import From File
2. Upload each workflow JSON file:
   - Content Planning Workflow
   - Script Generation Workflow
   - Visual Generation Workflow
   - Audio Generation Workflow
   - Assembly Readiness Workflow
   - Video Assembly Workflow
   - Publishing Workflow

### 4. Configure Webhooks

Check that all webhooks have the correct routes:

1. Open each workflow
2. Verify webhook paths match between workflows:
   - Content Planning Webhook → Script Generation Webhook
   - Script Generation → Audio/Visual Generation
   - Assembly Readiness → Video Assembly
   - Video Assembly → Publishing

## GPU Optimization for NVIDIA 3050

1. Create a configuration file at `C:\data\shared\configs\workflow_config.json`:
   ```powershell
   $configContent = @"
   {
     "contentSettings": {
       "defaultNiche": "tech",
       "defaultStyle": "informative",
       "defaultLength": "60s",
       "language": "en-US"
     },
     "publishingSettings": {
       "defaultPlatforms": ["youtube", "instagram", "tiktok", "facebook"],
       "postImmediately": true
     },
     "voiceSettings": {
       "elevenlabsVoiceId": "your-voice-id-here",
       "stability": 0.5,
       "similarityBoost": 0.75
     },
     "imageSettings": {
       "width": 768,
       "height": 768,
       "steps": 20,
       "cfgScale": 7,
       "sampler": "Euler a"
     }
   }
   "@
   
   Set-Content -Path "C:\data\shared\configs\workflow_config.json" -Value $configContent
   ```

2. Create a GPU monitoring script:
   ```powershell
   $monitorScript = @"
   # Monitor GPU resources
   `$logFile = "C:\data\shared\logs\resources_`$(Get-Date -Format 'yyyy-MM-dd').log"
   
   # Log header
   Add-Content -Path `$logFile -Value "======= Resource Monitor: `$(Get-Date) ======="
   
   # Memory usage
   Add-Content -Path `$logFile -Value "MEMORY USAGE:"
   [System.GC]::GetTotalMemory(`$true) / 1MB | ForEach-Object { Add-Content -Path `$logFile -Value "Total Memory: `$_MB" }
   
   # Disk space
   Add-Content -Path `$logFile -Value "DISK USAGE:"
   Get-Volume C | ForEach-Object { Add-Content -Path `$logFile -Value "C Drive: `$(`$_.SizeRemaining / 1GB)GB free of `$(`$_.Size / 1GB)GB" }
   
   # GPU usage
   Add-Content -Path `$logFile -Value "GPU USAGE:"
   nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.total,memory.used,temperature.gpu --format=csv | Add-Content -Path `$logFile
   
   # Running processes
   Add-Content -Path `$logFile -Value "CONTENT PROCESSES:"
   Get-Process -Name ffmpeg,python,node -ErrorAction SilentlyContinue | Add-Content -Path `$logFile
   
   Add-Content -Path `$logFile -Value "======= End of Report ======="
   "@
   
   Set-Content -Path "C:\data\shared\monitor_resources.ps1" -Value $monitorScript
   ```

3. Set up a scheduled task to run the monitoring script (use Windows Task Scheduler)

## Testing the System

1. Start all services:
   ```powershell
   docker-compose up -d
   ```

2. Start the AUTOMATIC1111 Stable Diffusion WebUI with API enabled
   
3. Ensure Ollama is running:
   ```powershell
   ollama serve
   ```

4. Test with a simple content generation:
   - Open n8n at http://localhost:5678
   - Go to the Content Planning Workflow
   - Click "Execute Workflow"
   - Enter test parameters:
     - niche: "tech"
     - style: "informative"
     - targetLength: "30s"
     - publishToYoutube: false (for testing)
   - Monitor workflow execution through each step

## Troubleshooting Windows-Specific Issues

### Docker Volume Mounting

If you encounter issues with Docker volumes:
```powershell
# Fix Docker volume mount permissions
$dockerConfigJson = Get-Content -Path "$env:USERPROFILE\.docker\config.json" | ConvertFrom-Json
$dockerConfigJson.shareDrives = @{"C" = $true}
$dockerConfigJson | ConvertTo-Json -Depth 10 | Set-Content -Path "$env:USERPROFILE\.docker\config.json"
```

### Path Format Issues

Windows paths need to be properly escaped in n8n functions:
```javascript
// Correct way to format Windows paths in n8n
const path = "C:\\data\\shared\\content";
// or
const path = "C:/data/shared/content"; // Also works in many contexts
```

### GPU Availability in Docker

If your GPU isn't available in the Docker container:
```powershell
# Check NVIDIA driver compatibility
docker run --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# Reinstall NVIDIA Container Toolkit if needed
wsl --shutdown
wsl
curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
sudo apt-get update
sudo apt-get install -y nvidia-container-runtime
sudo service docker restart
```

## Regular Maintenance

Set up a scheduled task to run maintenance operations:

```powershell
$maintenanceScript = @"
# Maintenance script for content cleanup
`$currentDate = Get-Date -Format 'yyyy-MM-dd'
`$logFile = "C:\data\shared\logs\maintenance_`$currentDate.log"

Add-Content -Path `$logFile -Value "Starting maintenance job at `$(Get-Date)"

# Delete content older than 14 days (except final videos)
Add-Content -Path `$logFile -Value "Cleaning up old content..."
Get-ChildItem -Path "C:\data\shared\video_*" -Directory | Where-Object {
    (`$_.LastWriteTime -lt (Get-Date).AddDays(-14)) -and
    -not (Test-Path -Path "`$(`$_.FullName)\final")
} | Remove-Item -Recurse -Force

# Compress logs older than 7 days
Add-Content -Path `$logFile -Value "Compressing old logs..."
Get-ChildItem -Path "C:\data\shared\logs\*.log" -File | Where-Object {
    (`$_.LastWriteTime -lt (Get-Date).AddDays(-7)) -and
    -not (`$_.Name -like "*.gz")
} | ForEach-Object {
    Compress-Archive -Path `$_.FullName -DestinationPath "`$(`$_.FullName).zip" -Force
    Remove-Item -Path `$_.FullName -Force
}

Add-Content -Path `$logFile -Value "Maintenance completed at `$(Get-Date)"
"@

Set-Content -Path "C:\data\shared\maintenance.ps1" -Value $maintenanceScript
```

Create a scheduled task to run this script weekly.

## Content Calendar Setup

Create a sample content calendar:

```powershell
$calendarContent = @"
[
  {
    "scheduledDate": "$(Get-Date -Format 'yyyy-MM-dd')",
    "niche": "tech",
    "style": "informative",
    "targetLength": "60s",
    "topic": "AI tools for content creators",
    "platforms": ["youtube", "instagram", "tiktok", "facebook"],
    "keywords": ["AI", "content creation", "productivity", "automation"],
    "priority": "high"
  },
  {
    "scheduledDate": "$(Get-Date).AddDays(1).ToString('yyyy-MM-dd')",
    "niche": "tech",
    "style": "tutorial",
    "targetLength": "90s",
    "topic": "Setting up a home server for content creators",
    "platforms": ["youtube", "instagram", "facebook"],
    "keywords": ["server", "home lab", "content creation", "data storage"],
    "priority": "medium"
  }
]
"@

Set-Content -Path "C:\data\shared\configs\content_calendar.json" -Value $calendarContent
```

## Conclusion

Your Windows-based n8n video content automation system is now set up and ready to use. The workflows are designed to work efficiently with your NVIDIA 3050 8GB GPU, using the AI Agent node to interact with Ollama for script generation and optimized settings for Stable Diffusion.

Remember to monitor GPU usage and adjust parameters as needed to prevent memory issues. The system is modular, so you can activate only the parts you need for specific content creation tasks.
