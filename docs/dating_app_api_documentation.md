# Dating App Mock Server API Documentation

## Base URL

```
http://localhost:3001
```

## Authentication

Most endpoints require authentication via JWT token. Include the token in the Authorization header:

```
Authorization: Bearer <token>
```

### Token Acquisition

Tokens are obtained through the login or registration endpoints. Each successful auth response includes:
- `token` - Access token for API calls
- `refreshToken` - Used to obtain a new access token when it expires

## API Endpoints

### Authentication

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/auth/register` | POST | No | Register a new user |
| `/auth/login` | POST | No | Login with credentials |
| `/auth/refresh` | POST | No | Refresh access token |
| `/auth/forgot-password` | POST | No | Request password reset |
| `/auth/logout` | POST | Yes | Logout current user |

#### Register Example

Request:
```json
{
  "email": "user@example.com", 
  "password": "password123", 
  "name": "User Name", 
  "birthDate": "1998-01-01", 
  "gender": "female"
}
```

Response (201):
```json
{
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "1234567890",
      "email": "user@example.com",
      "name": "User Name"
    },
    "profile": {
      "id": "profile-12345",
      "user_id": "1234567890",
      "name": "User Name",
      "gender": "female",
      "birth_date": "1998-01-01"
    },
    "token": "eyJhbGciOi...",
    "refreshToken": "eyJhbGciOi..."
  }
}
```

#### Login Example

Request:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Response (200):
```json
{
  "message": "Login successful",
  "data": {
    "user": {
      "id": "1234567890",
      "email": "user@example.com",
      "name": "User Name"
    },
    "profile": {
      "id": "profile-12345",
      "user_id": "1234567890"
    },
    "token": "eyJhbGciOi...",
    "refreshToken": "eyJhbGciOi..."
  }
}
```

#### Refresh Token Example

Request:
```json
{
  "refreshToken": "eyJhbGciOi..."
}
```

Response (200):
```json
{
  "message": "Token refreshed successfully",
  "accessToken": "eyJhbGciOi...",
  "refreshToken": "eyJhbGciOi..."
}
```

### User Management

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/users/me` | GET | Yes | Get current user profile |
| `/api/users/me` | PUT | Yes | Update current user |
| `/api/users/me` | DELETE | Yes | Delete user account |
| `/api/users/verify/request` | POST | Yes | Request verification |
| `/api/users/verify/confirm` | POST | Yes | Confirm verification with token |

#### Get Current User Example

Response (200):
```json
{
  "id": "1234567890",
  "email": "user@example.com",
  "name": "User Name",
  "created_at": "2025-04-20T12:00:00.000Z",
  "role": "user"
}
```

#### Update User Example

Request:
```json
{
  "email": "updated@example.com",
  "name": "Updated Name"
}
```

Response (200):
```json
{
  "id": "1234567890",
  "email": "updated@example.com",
  "name": "Updated Name",
  "created_at": "2025-04-20T13:00:00.000Z",
  "updated_at": "2025-04-20T13:00:00.000Z"
}
```

### Profile Management

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/profiles/me` | GET | Yes | Get current user's profile |
| `/api/profiles/me` | PUT | Yes | Update profile |
| `/api/profiles/me` | PATCH | Yes | Partially update profile |
| `/api/profiles/discover` | GET | Yes | Discover potential matches |
| `/api/profiles/verify` | GET | Yes | Get verification status |
| `/api/profiles/verify` | POST | Yes | Submit verification photo |
| `/api/profiles/preferences` | PUT | Yes | Update preferences |
| `/api/profiles/me/preferences` | PATCH | Yes | Update specific preferences |
| `/api/profiles/me/photos` | POST | Yes | Add profile photos |
| `/api/profiles/me/photos/:photoId` | DELETE | Yes | Delete specific photo |

#### Get Profile Example

Response (200):
```json
{
  "id": "profile-12345",
  "user_id": "1234567890",
  "name": "User Name",
  "birth_date": "1998-01-01",
  "gender": "female",
  "bio": "Sample bio text",
  "location": {
    "city": "New York",
    "country": "USA",
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "photos": [
    {
      "id": "photo-123",
      "url": "https://example.com/photo1.jpg"
    }
  ],
  "interests": ["hiking", "movies"],
  "preferences": {
    "age_min": 25,
    "age_max": 40,
    "distance_radius": 30,
    "gender_preference": ["male"]
  }
}
```

#### Update Profile Example

Request:
```json
{
  "bio": "Updated bio text",
  "interests": ["hiking", "movies", "cooking"]
}
```

Response (200):
```json
{
  "id": "profile-12345",
  "user_id": "1234567890",
  "bio": "Updated bio text",
  "interests": ["hiking", "movies", "cooking"],
  "updated_at": "2025-04-20T13:00:00.000Z"
}
```

#### Update Preferences Example

Request:
```json
{
  "age_min": 25,
  "age_max": 40,
  "distance_radius": 30,
  "gender_preference": ["female", "non-binary"]
}
```

Response (200):
```json
{
  "preferences": {
    "age_min": 25,
    "age_max": 40,
    "distance_radius": 30,
    "gender_preference": ["female", "non-binary"]
  },
  "updated_at": "2025-04-20T13:00:00.000Z"
}
```

#### Add Photos Example

Request:
```json
{
  "photoUrls": [
    "https://example.com/photo1.jpg",
    "https://example.com/photo2.jpg"
  ]
}
```

Response (200):
```json
{
  "success": true,
  "message": "Photos added successfully",
  "data": {
    "photos": [
      {
        "id": "photo-123",
        "url": "https://example.com/photo1.jpg"
      },
      {
        "id": "photo-124",
        "url": "https://example.com/photo2.jpg"
      }
    ]
  }
}
```

### Matches

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/matches` | GET | Yes | Get potential matches/discovery |
| `/api/matches/like` | POST | Yes | Like a profile |
| `/api/matches/pass` | POST | Yes | Pass on a profile |
| `/api/matches/undo` | POST | Yes | Undo last like/pass |
| `/api/matches/connections` | GET | Yes | Get mutual matches |
| `/api/matches/likes/me` | GET | Yes | Get profiles that liked you |
| `/api/matches/likes/sent` | GET | Yes | Get profiles you liked |

#### Like Profile Example

Request:
```json
{
  "profileId": "profile-54321"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Profile liked successfully"
}
```

Response (201 - Match created):
```json
{
  "success": true,
  "message": "It's a match!",
  "data": {
    "match_id": "match-12345",
    "created_at": "2025-04-20T13:00:00.000Z"
  }
}
```

### Settings

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/settings` | GET | Yes | Get general settings |
| `/api/settings` | PATCH | Yes | Update general settings |
| `/api/settings/notifications` | GET | Yes | Get notification settings |
| `/api/settings/notifications` | PATCH | Yes | Update notification settings |
| `/api/settings/privacy` | GET | Yes | Get privacy settings |
| `/api/settings/privacy` | PATCH | Yes | Update privacy settings |
| `/api/settings/account` | GET | Yes | Get account settings |

#### Update Settings Example

Request:
```json
{
  "dark_mode": true,
  "location_sharing": false
}
```

Response (200):
```json
{
  "id": "settings-12345",
  "userId": "1234567890",
  "notifications_enabled": true,
  "location_sharing": false,
  "dark_mode": true,
  "updated_at": "2025-04-20T13:00:00.000Z"
}
```

### Subscriptions

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/subscription-plans` | GET | No | Get available subscription plans |
| `/api/subscriptions` | GET | Yes | Get user's subscriptions |
| `/api/subscriptions` | POST | Yes | Create new subscription |

#### Get Subscription Plans Example

Response (200):
```json
[
  {
    "id": "monthly",
    "name": "Monthly",
    "price": 9.99,
    "interval": "month",
    "interval_count": 1,
    "features": ["unlimited_swipes", "see_likes", "global_mode"]
  },
  {
    "id": "yearly",
    "name": "Yearly",
    "price": 79.99,
    "interval": "year",
    "interval_count": 1,
    "features": ["unlimited_swipes", "see_likes", "global_mode", "rewind", "priority_matching"],
    "savings": "33%"
  }
]
```

#### Create Subscription Example

Request:
```json
{
  "planId": "monthly"
}
```

Response (201):
```json
{
  "id": "sub_12345",
  "userId": "1234567890",
  "planId": "monthly",
  "status": "active",
  "current_period_end": "2025-05-20T13:00:00.000Z",
  "created_at": "2025-04-20T13:00:00.000Z"
}
```

### Profile Actions

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/profile-actions` | POST | Yes | Block or report a profile |
| `/api/profile-actions/undo` | POST | Yes | Undo block/report action |
| `/api/profile-actions/history` | GET | Yes | Get action history |

#### Block/Report Profile Example

Request:
```json
{
  "profile_id": "profile-54321",
  "action_type": "block"
}
```

Response (201):
```json
{
  "success": true,
  "data": {
    "id": "action-12345",
    "user_id": "1234567890",
    "profile_id": "profile-54321",
    "action_type": "block",
    "created_at": "2025-04-20T13:00:00.000Z"
  }
}
```

## Common Response Patterns

### Success Responses

Responses for successful requests typically follow one of these patterns:

1. Direct resource return:
```json
{
  "id": "resource-id",
  "property1": "value1",
  "property2": "value2"
}
```

2. Wrapped resource with success message:
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    "id": "resource-id",
    "property1": "value1"
  }
}
```

### Error Responses

Error responses typically follow this pattern:
```json
{
  "success": false,
  "message": "Error description",
  "code": "ERROR_CODE"
}
```

Common HTTP status codes:
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Server Error

## Testing

A Python test script (`test_endpoints.py`) is available to verify all endpoints are working correctly. Run it with:

```
python test_endpoints.py
```

## Swagger Documentation

Interactive API documentation is available at:
```
http://localhost:3001/api-docs
```

## Further Information

For questions or issues, please contact the development team. 