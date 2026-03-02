import admin from 'firebase-admin';

// Initialize Firebase Admin (will use application default credentials)
admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

async function createJobPosterUser() {
  try {
    const email = 'jobposter@test.com';
    const password = 'Test123456';
    const displayName = 'Test Job Poster';
    const phoneNumber = '+923001234567';

    console.log('🔐 Creating Firebase Auth user...');

    // Create user in Firebase Authentication
    const userRecord = await auth.createUser({
      email: email,
      password: password,
      displayName: displayName,
      phoneNumber: phoneNumber,
    });

    console.log('✅ Firebase Auth user created:', userRecord.uid);

    // Create user document in Firestore
    console.log('📝 Creating Firestore document...');

    await db.collection('JobPosters').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      profileComplete: true,
      address: 'F-8, Islamabad',
      city: 'Islamabad',
    });

    console.log('✅ Firestore document created');
    console.log('\n🎉 Job Poster user created successfully!');
    console.log('\n📋 Login Credentials:');
    console.log('   Email:', email);
    console.log('   Password:', password);
    console.log('   UID:', userRecord.uid);
    console.log('\n💡 You can now login with these credentials');

  } catch (error) {
    console.error('❌ Error creating user:', error.message);

    if (error.code === 'auth/email-already-exists') {
      console.log('\n💡 User already exists. Trying to get existing user...');
      try {
        const existingUser = await auth.getUserByEmail('jobposter@test.com');
        console.log('✅ Existing user UID:', existingUser.uid);
        console.log('   Email: jobposter@test.com');
        console.log('   Password: Test123456 (if not changed)');
      } catch (err) {
        console.error('Error fetching existing user:', err.message);
      }
    }
  } finally {
    process.exit(0);
  }
}

createJobPosterUser();
