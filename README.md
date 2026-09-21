# GMU Alumni Connect - Flutter Mobile App

A comprehensive mobile application for GMU Alumni with all website features.

## Features

✅ **Authentication**
- Login/Register
- Profile Management
- Secure token-based authentication

✅ **Core Features**
- Home Dashboard
- Core Team Display
- Noticeboard
- News Corner
- Photo Galleries
- Events Calendar
- Jobs Portal
- Proud Alumni
- User Profile

## Setup Instructions

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Android Studio / VS Code
- PHP 7.4+ with MySQL
- XAMPP or similar local server

### Backend Setup

1. **Copy API files to your server:**
   ```
   Copy the 'api' folder to: C:\xampp_ss\htdocs\alumni\api\
   ```

2. **Update database (if needed):**
   - Add `auth_token` column to users table:
   ```sql
   ALTER TABLE users ADD COLUMN auth_token VARCHAR(255) NULL;
   ALTER TABLE users ADD COLUMN last_login DATETIME NULL;
   ```

3. **Test API endpoints:**
   - Open browser: `http://localhost/alumni/api/core-team/list.php`
   - Should return JSON response

### Mobile App Setup

1. **Navigate to app directory:**
   ```bash
   cd gmu_alumni_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update API configuration:**
   - Open `lib/config/app_config.dart`
   - Update `baseUrl` with your server IP/domain:
   ```dart
   static const String baseUrl = 'http://192.168.1.100/alumni';
   ```
   - For Android emulator use: `http://10.0.2.2/alumni`
   - For physical device use your computer's IP address

4. **Run the app:**
   ```bash
   flutter run
   ```

## Project Structure

```
gmu_alumni_app/
├── lib/
│   ├── config/
│   │   └── app_config.dart          # API endpoints & app configuration
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── notice_model.dart
│   │   ├── news_model.dart
│   │   ├── event_model.dart
│   │   ├── job_model.dart
│   │   ├── gallery_model.dart
│   │   └── core_team_model.dart
│   ├── providers/
│   │   └── auth_provider.dart       # State management for auth
│   ├── routes/
│   │   └── app_router.dart          # Navigation routes
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── core_team_screen.dart
│   │   ├── noticeboard_screen.dart
│   │   ├── news_screen.dart
│   │   ├── galleries_screen.dart
│   │   ├── events_screen.dart
│   │   ├── jobs_screen.dart
│   │   ├── proud_alumni_screen.dart
│   │   └── profile_screen.dart
│   ├── services/
│   │   └── api_service.dart         # HTTP client
│   ├── widgets/
│   │   └── app_drawer.dart          # Navigation drawer
│   └── main.dart
└── pubspec.yaml
```

## API Endpoints

All endpoints return JSON format:

### Authentication
- `POST /api/auth/login.php` - User login
- `POST /api/auth/register.php` - User registration

### Data Endpoints
- `GET /api/core-team/list.php` - Get core team members
- `GET /api/noticeboard/list.php` - Get notices
- `GET /api/news/list.php` - Get news articles
- `GET /api/events/list.php` - Get events
- `GET /api/jobs/list.php` - Get job listings
- `GET /api/galleries/list.php` - Get photo galleries
- `GET /api/proud-alumni/list.php` - Get proud alumni
- `GET /api/profile/me.php` - Get user profile (requires auth token)

## Testing

### Test Login
- Email: any email in your database
- Password: corresponding password

### Test API
```bash
# Test core team endpoint
curl http://localhost/alumni/api/core-team/list.php

# Test login
curl -X POST http://localhost/alumni/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## Building for Production

### Android
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### Common Issues

1. **API not connecting:**
   - Check if XAMPP is running
   - Verify API URL in `app_config.dart`
   - For Android emulator, use `10.0.2.2` instead of `localhost`
   - For physical device, use computer's IP address

2. **Dependencies error:**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Build errors:**
   ```bash
   flutter doctor
   ```

## Next Steps

1. **Implement real API calls** in screens (currently using sample data)
2. **Add image caching** for better performance
3. **Implement push notifications**
4. **Add offline support** with local database
5. **Implement search functionality**
6. **Add filters and sorting**
7. **Implement file uploads** for profile pictures
8. **Add social features** (comments, likes, shares)

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

Copyright © 2024 GMU Alumni Connect

## Support

For issues and questions:
- Email: support@gmualumni.com
- GitHub Issues: [Create an issue]

---

**Note:** Remember to update the `baseUrl` in `app_config.dart` before deploying to production!
