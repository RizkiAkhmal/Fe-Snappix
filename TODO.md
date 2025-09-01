# TODO: Update Profile Page to Display Logged-in User Name and Email

## Tasks
- [x] Load stored name from SharedPreferences in profile page
- [x] Update name display logic to use stored name as fallback
- [x] Ensure email is displayed with proper fallback
- [x] Test the changes to verify name and email display correctly
- [x] Add album detail navigation functionality

## Files to Edit
- lib/pages/profile_page.dart
- lib/services/post_service.dart
- lib/pages/album_detail_page.dart

## Notes
- Use stored name from login as fallback when API data is unavailable
- Display email if available from API, otherwise show placeholder
- Added navigation to album detail page showing all posts in selected album
