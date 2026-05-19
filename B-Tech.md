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


# Settings → About phone → Tap “Build number” 7 times

# Settings → Developer options
✅ debugging → ON
✅ USB debugging (Security settings) → ON

# After plugging the cable in:
Swipe down → USB notification
Select File Transfer (MTP)

# Pov's Accounts

# Admin
Admin123@gmail.com
adminadmin

# User 
user1@gmail.com
asdASD123

# Shop
laundry1@gmail.com
asdASD123

# Driver
ahmeddriver@gmail.com
asdASD123


# testing commands 
flutter test test/forgot_password_validation_test.dart
flutter test test/login_validation_test.dart
flutter test test/add_laundry_service_validation_test.dart
flutter test test/edit_service_validation_test.dart


# Flow 
Cart → Checkout → Pick Date & Time Slot → 
Pay → Order created in Firestore (status: pending, paymentStatus: paid) →
Shop Owner confirms → processes → marks ready →
Driver accepts → delivers →
Customer tracks everything in Orders tab

Updated Full Order Lifecycle
Step	Status	Who presses what	Tracker lights up
1	pending	Customer places order	✅ Step 1
2	picked	Driver accepts pickup	✅ Step 2 "Driver Assigned"
3	collected	Driver taps "Collected from Customer ✓"	✅ Step 3 "Laundry Collected"
4	in_progress	Shop taps Start Processing	✅ Step 4 "Being Cleaned"
5	ready	Shop taps Mark as Ready	✅ Step 5 "Ready for Delivery"
6	out_for_delivery	Driver accepts delivery	✅ Step 6 "Out for Delivery"
7	delivered	Driver taps Mark as Delivered	✅ Step 7 "Delivered"ASD

