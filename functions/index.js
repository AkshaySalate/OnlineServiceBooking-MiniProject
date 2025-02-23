/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin (if not already initialized)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

exports.updateProviderEarnings = functions.firestore
    .document("bookings/{bookingId}")
    .onUpdate(async (change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();

        // Only proceed if status changed to "Completed"
        if (previousValue.status !== "Completed" && newValue.status === "Completed") {
            const providerRef = admin.firestore().collection("providers").doc(newValue.providerID);
            const earningsRef = admin.firestore().collection("earnings");

            // Add a new earning entry in Earnings Collection
            await earningsRef.add({
                providerID: newValue.providerID,
                bookingID: context.params.bookingId,
                amount: newValue.amount,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Update provider's total earnings
            await providerRef.update({
                totalEarnings: admin.firestore.FieldValue.increment(newValue.amount)
            });

            console.log(`✅ Earnings updated for provider: ${newValue.providerID}`);
        }
    });

