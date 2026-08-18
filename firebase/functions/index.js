const functions = require("firebase-functions/v1");
const {logger} = require("firebase-functions");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");

initializeApp();

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const firestore = getFirestore();
  const bucket = getStorage().bucket();
  const cleanupTasks = [
    firestore.recursiveDelete(firestore.doc(`users/${user.uid}`)),
    firestore.recursiveDelete(firestore.doc(`organizers/${user.uid}`)),
    bucket.deleteFiles({prefix: `users/${user.uid}/`}),
    bucket.deleteFiles({prefix: `organizers/${user.uid}/`}),
    bucket.deleteFiles({prefix: `events/${user.uid}/`}),
  ];
  const results = await Promise.allSettled(cleanupTasks);
  const failures = results.filter((result) => result.status === "rejected");

  if (failures.length > 0) {
    failures.forEach((failure) => logger.error(
        "User cleanup operation failed",
        failure.reason,
    ));
    throw new Error(`Failed ${failures.length} user cleanup operation(s).`);
  }
});
