import admin from 'firebase-admin';

// Initialize Firebase Admin (will use application default credentials)
admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

async function createJobPosterWithPhone() {
  try {
    const phoneNumber = '+923001234567';
    const displayName = 'Test Job Poster';
    const email = 'jobposter@test.com';

    console.log('🔐 Creating Firebase Auth user with phone number...');

    // Create user in Firebase Authentication with phone number
    const userRecord = await auth.createUser({
      phoneNumber: phoneNumber,
      displayName: displayName,
      email: email,
      emailVerified: true,
    });

    console.log('✅ Firebase Auth user created:', userRecord.uid);

    // Create user document in Firestore
    console.log('📝 Creating Firestore document in JobPosters collection...');

    await db.collection('JobPosters').doc(userRecord.uid).set({
      userId: userRecord.uid,
      phoneNumber: phoneNumber,
      displayName: displayName,
      email: email,
      isActive: true,
      isVerified: true,
      userType: 'job_poster',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
      profileCompleted: false,
      settings: {
        notifications: true,
        emailNotifications: false,
        smsNotifications: true,
      },
      stats: {
        jobsPosted: 0,
        jobsCompleted: 0,
        totalSpent: 0.0
      }
    });

    console.log('✅ Firestore document created');
    console.log('\n🎉 Job Poster user created successfully!');
    console.log('\n📋 Login Credentials:');
    console.log('   Phone Number:', phoneNumber);
    console.log('   UID:', userRecord.uid);
    console.log('   Display Name:', displayName);
    console.log('\n💡 The user is now verified and can login with phone number');
    console.log('   Note: You may still need to enter OTP when logging in via the app');
    console.log('   as Firebase requires OTP verification for phone auth sign-ins.');

  } catch (error) {
    console.error('❌ Error creating user:', error.message);

    if (error.code === 'auth/phone-number-already-exists') {
      console.log('\n💡 User with this phone number already exists.');
      try {
        const existingUser = await auth.getUserByPhoneNumber('+923001234567');
        console.log('✅ Existing user UID:', existingUser.uid);
        console.log('   Phone:', existingUser.phoneNumber);
        console.log('   Display Name:', existingUser.displayName);
      } catch (err) {
        console.error('Error fetching existing user:', err.message);
      }
    }
  } finally {
    process.exit(0);
  }
}

createJobPosterWithPhone();
