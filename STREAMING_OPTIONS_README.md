# Streaming Options Feature

## Overview
The Streaming Options feature allows users to see where movies are available to stream, with automatic syncing from the Movie of the Night API. This system has been optimized for free API tier usage with frequent progress saving.

## Key Features

### 🎯 Optimized for Free API Tier
- **Netflix Only**: Limited to Netflix streaming data only to reduce API calls
- **US/English Content**: Focuses on US region and English language content
- **Frequent Progress Saving**: Saves progress every 5 API calls to prevent data loss if sync is cancelled
- **Incremental Updates**: Uses changes endpoint to avoid re-syncing everything

### 🔄 Smart Sync System
- **Initial Sync**: Full sync for first-time setup
- **Incremental Updates**: Only fetches changes since last sync
- **Configurable Intervals**: Easy to adjust sync frequency
- **Progress Tracking**: Real-time status updates during sync

### 🎨 User Interface
- **Platform Selection**: Modal dialog with streaming platform grid
- **Loading Screen**: Animated app logo with sync status
- **Persistent Settings**: User platform preferences saved locally
- **App Bar Integration**: Easy access to platform filters

## Configuration

### API Rate Limits
The system respects the free tier API limits:
- **200ms delay** between API calls
- **Progress saving** every 5 API calls
- **Netflix only** to minimize API usage
- **English content only** to reduce data volume

### Sync Intervals
```dart
// In AppConfig class
static const Duration streamingOptionsSyncInterval = Duration(minutes: 1); // For testing
// Change to: Duration(days: 3) for production
```

### Platform Selection
Default platform selection is now Netflix only:
```dart
// In StreamingPlatformsCubit
if (selectedIds.isEmpty) {
  selectedIds.addAll(['netflix']); // Optimized for free tier
}
```

## Database Schema

### Movies Table
```sql
ALTER TABLE master_movies 
ADD COLUMN streaming_options TEXT DEFAULT NULL;
```

### Metadata Table
```sql
CREATE TABLE streaming_update_metadata (
  id INTEGER PRIMARY KEY,
  last_update_timestamp INTEGER
);
```

## API Integration

### Movie of the Night API
- **Base URL**: `https://streaming-availability.p.rapidapi.com`
- **Service ID**: `netflix` (not `netflix_com`)
- **Country**: `us`
- **Language**: `en`

### Endpoints Used
1. **Search/Filters**: `/shows/search/filters` - For initial sync
2. **Changes**: `/changes` - For incremental updates

### Request Parameters
```dart
final queryParams = {
  'country': 'us',
  'catalogs': 'netflix',
  'show_type': 'movie',
  'order_by': 'popularity_1year',
  'order_direction': 'desc',
  'output_language': 'en',
  'language': 'en', // English content only
};
```

## Usage Guide

### For Users
1. **Login** to the app
2. **Loading screen** appears with sync status
3. **Platform filter** button in app bar
4. **Select platforms** in modal dialog
5. **Browse movies** with streaming availability

### For Developers
1. **Add API key** to `.env` file:
   ```
   MOVIE_OF_THE_NIGHTS_API_KEY=your_key_here
   ```
2. **Adjust sync interval** in `AppConfig`
3. **Monitor API usage** in console logs
4. **Extend platform support** by updating `catalogs` list

## Performance Optimizations

### Memory Management
- **Batch processing**: Processes movies in batches
- **Progress clearing**: Clears processed batches from memory
- **Lazy loading**: Loads streaming data as needed

### API Efficiency
- **Cursor-based pagination**: Efficient data fetching
- **Change tracking**: Avoids redundant API calls
- **Error recovery**: Continues sync after errors

### Database Optimization
- **Batch updates**: Groups database operations
- **JSON storage**: Efficient streaming options storage
- **Indexed queries**: Fast movie lookups

## Error Handling

### API Errors
- **Rate limiting**: Automatic delay between calls
- **Service errors**: Graceful fallback and retry
- **Network issues**: Progress preservation on failure

### Database Errors
- **Migration safety**: Handles existing columns
- **Transaction rollback**: Ensures data consistency
- **Backup recovery**: Preserves data on errors

## Monitoring & Logging

### Progress Tracking
```
Starting optimized sync with progress saving every 5 API calls...
Processed API page 1 with 100 shows
Found streaming options for: Movie Title
Progress saved! Processed 500 movies with 5 API calls
```

### API Usage Monitoring
```
API request failed with status: 429
Total shows fetched from API: 1500
Final batch saved! Total processed: 800 movies with 15 API calls
```

## Future Enhancements

### Planned Features
- **Multiple platforms**: When API limits allow
- **Advanced filtering**: Genre, rating, year filters
- **Offline support**: Cache streaming data locally
- **Push notifications**: Alert when favorites become available

### Technical Improvements
- **GraphQL support**: More efficient data fetching
- **Real-time updates**: WebSocket integration
- **Caching layer**: Reduce API dependency
- **Background sync**: Automatic updates without user interaction

## Troubleshooting

### Common Issues
1. **API Key Missing**: Check `.env` file
2. **Network Timeout**: Increase delay between calls
3. **Database Locked**: Ensure proper transaction handling
4. **Sync Interrupted**: Check progress saving logs

### Performance Tips
- **Reduce sync frequency** for production
- **Monitor API usage** to avoid limits
- **Clear old data** periodically
- **Use incremental updates** instead of full sync

## Testing

### Test Scenarios
1. **Initial sync**: Fresh database sync
2. **Incremental update**: Changes since last sync
3. **Error recovery**: Handling API failures
4. **Progress preservation**: Cancelling and resuming sync

### Test Data
- **Sample movies**: Use small movie database
- **Mock API**: Test without real API calls
- **Error simulation**: Test error handling paths

---

*Last updated: [Current Date]*
*API Version: Movie of the Night API v1*
*Flutter Version: 3.x* 