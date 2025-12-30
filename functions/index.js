/**
 * Cloud Functions for GLIMO
 *
 * Receipt Verification & Subscription Management
 *
 * DEMO MODE: Mock verification for testing
 * PRODUCTION: Enable real Google Play verification
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// ============================================================================
// CONFIGURATION
// ============================================================================

const DEMO_MODE = true; // Set to false for production Google Play verification

// ============================================================================
// VERIFY PURCHASE (Mock Mode for Demo/Testing)
// ============================================================================

/**
 * Verify purchase with Google Play Billing
 *
 * Demo Mode: Simulates successful verification
 * Production Mode: Calls Google Play Developer API
 *
 * @param {object} data - {purchaseToken, productId, packageName}
 * @param {object} context - Firebase Auth context
 * @returns {Promise<object>} - {success: boolean, expiryDate: number}
 */
exports.verifyPurchase = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to verify purchases'
    );
  }

  const { purchaseToken, productId, packageName } = data;
  const userId = context.auth.uid;

  console.log(`📱 Verifying purchase for user: ${userId}, product: ${productId}`);

  try {
    if (DEMO_MODE) {
      // =====================================================================
      // DEMO MODE: Mock Verification (for testing/presentation)
      // =====================================================================
      console.log('🎮 DEMO MODE: Simulating purchase verification...');

      // Simulate verification delay
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Calculate expiry date based on product
      const now = Date.now();
      let durationMonths = 1; // Default: monthly

      if (productId === 'glimo_premium_yearly') {
        durationMonths = 12;
      } else if (productId === 'glimo_premium_monthly') {
        durationMonths = 1;
      }

      const expiryDate = now + (durationMonths * 30 * 24 * 60 * 60 * 1000);

      // Save verified subscription to Firestore
      await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .set({
          isActive: true,
          expiryDate: expiryDate,
          startDate: now,
          plan: productId === 'glimo_premium_yearly' ? 'Yearly Premium' : 'Monthly Premium',
          isTrial: false,
          productId: productId,
          platform: 'android',
          purchaseToken: purchaseToken || 'DEMO_TOKEN',
          verified: true,
          verifiedAt: now,
          demoMode: true,
        }, { merge: true });

      console.log(`✅ DEMO MODE: Purchase verified successfully!`);
      console.log(`📅 Expiry date: ${new Date(expiryDate).toISOString()}`);

      return {
        success: true,
        expiryDate: expiryDate,
        plan: productId === 'glimo_premium_yearly' ? 'Yearly Premium' : 'Monthly Premium',
        demoMode: true,
      };

    } else {
      // =====================================================================
      // PRODUCTION MODE: Real Google Play Verification
      // =====================================================================
      console.log('🔐 PRODUCTION MODE: Verifying with Google Play...');

      // TODO: Implement real Google Play Developer API verification
      // const { google } = require('googleapis');
      // const androidPublisher = google.androidpublisher('v3');
      //
      // const authClient = await google.auth.getClient({
      //   scopes: ['https://www.googleapis.com/auth/androidpublisher']
      // });
      //
      // const result = await androidPublisher.purchases.subscriptions.get({
      //   auth: authClient,
      //   packageName: packageName,
      //   subscriptionId: productId,
      //   token: purchaseToken,
      // });
      //
      // const expiryTime = parseInt(result.data.expiryTimeMillis);
      //
      // await admin.firestore()
      //   .collection('users')
      //   .doc(userId)
      //   .collection('subscription')
      //   .doc('current')
      //   .set({
      //     isActive: expiryTime > Date.now(),
      //     expiryDate: expiryTime,
      //     purchaseToken: purchaseToken,
      //     productId: productId,
      //     platform: 'android',
      //     verified: true,
      //     verifiedAt: Date.now(),
      //   }, { merge: true });
      //
      // return { success: true, expiryDate: expiryTime };

      throw new functions.https.HttpsError(
        'unimplemented',
        'Production verification not yet implemented. Set DEMO_MODE = true for testing.'
      );
    }

  } catch (error) {
    console.error('❌ Verification error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to verify purchase: ' + error.message
    );
  }
});

// ============================================================================
// RESTORE PURCHASES
// ============================================================================

/**
 * Restore user's active subscriptions
 * Checks Firestore for existing verified subscriptions
 *
 * @param {object} data - {}
 * @param {object} context - Firebase Auth context
 * @returns {Promise<object>} - {success: boolean, subscription: object}
 */
exports.restorePurchases = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;

  try {
    const doc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('subscription')
      .doc('current')
      .get();

    if (doc.exists) {
      const subscription = doc.data();
      const isActive = subscription.isActive && subscription.expiryDate > Date.now();

      return {
        success: true,
        subscription: {
          isActive: isActive,
          plan: subscription.plan,
          expiryDate: subscription.expiryDate,
        },
      };
    }

    return { success: false, subscription: null };

  } catch (error) {
    console.error('Error restoring purchases:', error);
    throw new functions.https.HttpsError('internal', 'Failed to restore purchases');
  }
});

// ============================================================================
// SCHEDULED: Check Expired Subscriptions (Daily)
// ============================================================================

/**
 * Runs daily to check and deactivate expired subscriptions
 * Scheduled function to keep subscription status accurate
 */
exports.checkExpiredSubscriptions = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    console.log('🔍 Checking for expired subscriptions...');

    const now = Date.now();
    const usersRef = admin.firestore().collection('users');
    const usersSnapshot = await usersRef.get();

    let expiredCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const subRef = userDoc.ref.collection('subscription').doc('current');
      const subDoc = await subRef.get();

      if (subDoc.exists) {
        const sub = subDoc.data();
        if (sub.isActive && sub.expiryDate < now) {
          // Subscription expired, deactivate
          await subRef.update({
            isActive: false,
            deactivatedAt: now,
          });
          expiredCount++;
          console.log(`⏰ Deactivated expired subscription for user: ${userDoc.id}`);
        }
      }
    }

    console.log(`✅ Checked subscriptions. Expired: ${expiredCount}`);
    return null;
  });

console.log('🚀 GLIMO Cloud Functions loaded successfully!');
console.log(`⚙️  Demo Mode: ${DEMO_MODE ? 'ENABLED' : 'DISABLED'}`);
