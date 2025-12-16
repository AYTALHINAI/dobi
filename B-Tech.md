# flutter test test/login_test.dart
# flutter test test/forgot_password_validation_test.dart

# Shop
Based on the city, governorate and shops would show for the user based on their locations 

# User 
Will enter the city, governorate or the location mandatory if he wants something delivered, so that later we can use the city to 
show possible deliveries for the driver 

# Driver
Location preference after approval next semester
The driver picks the city name and based on it he will get the possible deliveries

# About Password Encryption
Firebase Authentication already handles password security - when you create a user with createUserWithEmailAndPassword, Firebase:
    - Hashes the password using industry-standard bcrypt
    - Never stores passwords in plaintext
    - All transmission is over HTTPS (encrypted in transit)
    - You should not encrypt passwords before sending to Firebase Auth, as this would break the authentication flow.