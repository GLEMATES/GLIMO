/**
 * Script untuk verify email demo account
 */

const admin = require('firebase-admin');
const serviceAccount = require('./functions/node_modules/firebase-admin/lib/app/credential-internal.js');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'glimo-2eff0'
});

const auth = admin.auth();

async function verifyEmail() {
  const email = 'glemo.reviewer@gmail.com';

  try {
    console.log('🔍 Finding user:', email);

    const userRecord = await auth.getUserByEmail(email);

    console.log('✅ User found!');
    console.log('   Email:', userRecord.email);
    console.log('   UID:', userRecord.uid);
    console.log('   Email Verified:', userRecord.emailVerified);

    if (userRecord.emailVerified) {
      console.log('✅ Email already verified!');
    } else {
      console.log('🔧 Verifying email...');

      await auth.updateUser(userRecord.uid, {
        emailVerified: true
      });

      console.log('✅ Email verified successfully!');
    }

    console.log('\n🎉 Demo account ready!');
    console.log('   Email: glemo.reviewer@gmail.com');
    console.log('   Password: ReviewerGlemo2025!');
    console.log('   Status: Email Verified ✓');

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

verifyEmail();
