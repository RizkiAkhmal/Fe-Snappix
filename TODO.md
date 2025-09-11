# Fix Search Errors and Performance

## Backend Changes
- [x] Update UserApiController.php: Change validation from 'query' to 'q' in searchUsers method

## Frontend Changes
- [x] Update profile_service.dart: Modify searchUsers to use correct URL /user/search?q=... and remove inefficient fallbacks

## Optional Optimizations
- [ ] Add database indexes on 'name' and 'username' columns in users table

## Testing
- [ ] Test search functionality to ensure 422 and 404 errors are resolved
- [ ] Verify search response time is improved
