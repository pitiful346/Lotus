const functions = require("firebase-functions/v1");
const {logger} = require("firebase-functions");
const crypto = require("node:crypto");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
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

const TIME_ZONE = "Europe/Lisbon";
const MAX_DAILY_NOTIFICATIONS = 3;
const QUIET_HOURS_START = 22;
const QUIET_HOURS_END = 8;
const STALE_DEVICE_DAYS = 35;

exports.onFavoriteEventChanged = functions.firestore
    .document("events/{eventId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      const changed = changedEventFields(before, after);
      if (changed.length === 0) return null;

      const title = after.name || "Evento guardado";
      const description = eventChangeDescription(changed);
      await forEachFavoriteOwner(change.after.ref, async (userId) => {
        await queueNotification({
          userId,
          type: "favorite_changed",
          dedupeKey: `favorite_changed:${context.params.eventId}:` +
            `${change.after.updateTime.toMillis()}`,
          title,
          body: description,
          eventId: context.params.eventId,
        });
      });
      return null;
    });

exports.queueUpcomingFavoriteEvents = functions.pubsub
    .schedule("every 60 minutes")
    .timeZone(TIME_ZONE)
    .onRun(async () => {
      const firestore = getFirestore();
      const now = new Date();
      const from = Timestamp.fromDate(new Date(now.getTime() + 23 * 60 * 60 * 1000));
      const until = Timestamp.fromDate(new Date(now.getTime() + 25 * 60 * 60 * 1000));
      const events = await firestore.collection("events")
          .where("is_archived", "==", false)
          .where("start_date", ">=", from)
          .where("start_date", "<", until)
          .limit(200)
          .get();

      for (const event of events.docs) {
        const data = event.data();
        await forEachFavoriteOwner(event.ref, async (userId) => {
          await queueNotification({
            userId,
            type: "favorite_starting_soon",
            dedupeKey: `favorite_starting_soon:${event.id}:` +
              `${data.start_date.toMillis()}`,
            title: data.name || "Evento favorito",
            body: "Começa dentro de cerca de 24 horas.",
            eventId: event.id,
          });
        });
      }
      return null;
    });

exports.queueWeeklyRecommendations = functions.pubsub
    .schedule("0 10 * * 1")
    .timeZone(TIME_ZONE)
    .onRun(async () => {
      const firestore = getFirestore();
      const preferences = await firestore.collectionGroup("preferences")
          .where("recommendations", "==", true)
          .limit(1000)
          .get();
      const week = localDayKey(new Date()).slice(0, 7) +
        `:${weekOfYear(new Date())}`;

      for (const preference of preferences.docs) {
        if (preference.id !== "notifications") continue;
        const user = preference.ref.parent.parent;
        if (user == null) continue;
        await queueNotification({
          userId: user.id,
          type: "recommendations_digest",
          dedupeKey: `recommendations_digest:${week}`,
          title: "Sugestões para ti",
          body: "Há novos eventos alinhados com os teus interesses.",
          data: {route: "saved"},
        });
      }
      return null;
    });

exports.dispatchPendingNotifications = functions.pubsub
    .schedule("every 15 minutes")
    .timeZone(TIME_ZONE)
    .onRun(async () => {
      const firestore = getFirestore();
      const pending = await firestore.collection("notification_queue")
          .where("status", "==", "pending")
          .where("scheduled_at", "<=", Timestamp.now())
          .orderBy("scheduled_at")
          .limit(200)
          .get();
      await Promise.allSettled(pending.docs.map(deliverNotification));
      return null;
    });

async function queueNotification({
  userId,
  type,
  dedupeKey,
  title,
  body,
  eventId,
  data,
}) {
  const firestore = getFirestore();
  const id = crypto.createHash("sha256")
      .update(`${userId}:${dedupeKey}`)
      .digest("hex");
  const reference = firestore.collection("notification_queue").doc(id);
  const now = new Date();
  const scheduledAt = nextAllowedTime(now);
  await firestore.runTransaction(async (transaction) => {
    const existing = await transaction.get(reference);
    if (existing.exists) return;
    transaction.create(reference, {
      user_id: userId,
      type,
      title,
      body,
      data: eventId ? {eventId} : (data || {}),
      status: "pending",
      scheduled_at: Timestamp.fromDate(scheduledAt),
      created_at: FieldValue.serverTimestamp(),
    });
  });
}

async function deliverNotification(queueDocument) {
  const firestore = getFirestore();
  const queue = queueDocument.data();
  const userId = queue.user_id;
  const preferenceReference = firestore.doc(
      `users/${userId}/preferences/notifications`,
  );
  const preference = await preferenceReference.get();
  if (!preference.exists || !preferenceAllows(preference.data(), queue.type)) {
    await queueDocument.ref.update({status: "suppressed_disabled"});
    return;
  }

  const now = new Date();
  if (isQuietHour(now)) {
    await queueDocument.ref.update({
      scheduled_at: Timestamp.fromDate(nextAllowedTime(now)),
    });
    return;
  }

  const devices = await firestore.collection(`users/${userId}/devices`)
      .where("enabled", "==", true)
      .limit(500)
      .get();
  const freshDevices = devices.docs.filter((device) => {
    const updatedAt = device.data().updated_at;
    return updatedAt && updatedAt.toMillis() >=
      now.getTime() - STALE_DEVICE_DAYS * 24 * 60 * 60 * 1000;
  });
  const staleDevices = devices.docs.filter(
      (device) => !freshDevices.includes(device),
  );
  await Promise.allSettled(staleDevices.map((device) => device.ref.delete()));
  if (freshDevices.length === 0) {
    await queueDocument.ref.update({status: "no_active_devices"});
    return;
  }

  const deliveryReference = firestore.doc(
      `users/${userId}/notification_delivery/${localDayKey(now)}`,
  );
  const reserved = await firestore.runTransaction(async (transaction) => {
    const [freshQueue, delivery] = await Promise.all([
      transaction.get(queueDocument.ref),
      transaction.get(deliveryReference),
    ]);
    if (freshQueue.data()?.status !== "pending") return false;
    const delivered = delivery.data()?.count || 0;
    if (delivered >= MAX_DAILY_NOTIFICATIONS) {
      transaction.update(queueDocument.ref, {status: "suppressed_daily_limit"});
      return false;
    }
    transaction.set(deliveryReference, {
      count: delivered + 1,
      updated_at: FieldValue.serverTimestamp(),
    }, {merge: true});
    transaction.update(queueDocument.ref, {status: "sending"});
    return true;
  });
  if (!reserved) return;

  const tokens = freshDevices.map((device) => device.data().token);
  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {title: queue.title, body: queue.body},
      data: stringData(queue.data),
      android: {priority: "high", notification: {sound: "default"}},
      apns: {payload: {aps: {sound: "default"}}},
    });
    await removeInvalidDevices(freshDevices, response.responses);
    const deliveredAt = FieldValue.serverTimestamp();
    const status = response.successCount > 0 ? "sent" : "failed";
    await Promise.all([
      queueDocument.ref.update({status, delivered_at: deliveredAt}),
      firestore.doc(`users/${userId}/notifications/${queueDocument.id}`).set({
        type: queue.type,
        title: queue.title,
        body: queue.body,
        data: queue.data || {},
        status,
        created_at: queue.created_at || deliveredAt,
        delivered_at: deliveredAt,
      }),
    ]);
  } catch (error) {
    logger.error("Notification delivery failed", {
      queueId: queueDocument.id,
      userId,
      error,
    });
    await queueDocument.ref.update({status: "failed"});
  }
}

async function forEachFavoriteOwner(eventReference, callback) {
  const firestore = getFirestore();
  let lastDocument = null;
  do {
    let query = firestore.collectionGroup("favorites")
        .where("event_ref", "==", eventReference)
        .orderBy("__name__")
        .limit(250);
    if (lastDocument != null) query = query.startAfter(lastDocument);
    const favorites = await query.get();
    for (const favorite of favorites.docs) {
      const user = favorite.ref.parent.parent;
      if (user != null) await callback(user.id);
    }
    lastDocument = favorites.docs.at(-1) || null;
    if (favorites.size < 250) break;
  } while (lastDocument != null);
}

async function removeInvalidDevices(devices, responses) {
  const invalidCodes = new Set([
    "messaging/invalid-registration-token",
    "messaging/registration-token-not-registered",
  ]);
  const removals = [];
  responses.forEach((response, index) => {
    if (!response.success && invalidCodes.has(response.error?.code)) {
      removals.push(devices[index].ref.delete());
    }
  });
  await Promise.allSettled(removals);
}

function preferenceAllows(preferences, type) {
  if (type === "favorite_changed") {
    return preferences.favorite_event_updates === true;
  }
  if (type === "favorite_starting_soon") {
    return preferences.upcoming_favorite_events === true;
  }
  if (type === "recommendations_digest") {
    return preferences.recommendations === true;
  }
  return false;
}

function changedEventFields(before, after) {
  return ["start_date", "location", "venue_name", "coordenadas", "is_archived"]
      .filter((field) => comparable(before[field]) !== comparable(after[field]));
}

function comparable(value) {
  if (value == null) return "";
  if (typeof value.toMillis === "function") return `${value.toMillis()}`;
  if (typeof value.latitude === "number") {
    return `${value.latitude},${value.longitude}`;
  }
  return JSON.stringify(value);
}

function eventChangeDescription(fields) {
  if (fields.includes("is_archived")) {
    return "O estado deste evento foi alterado. Consulta os detalhes.";
  }
  const dateChanged = fields.includes("start_date");
  const placeChanged = fields.some(
      (field) => ["location", "venue_name", "coordenadas"].includes(field),
  );
  if (dateChanged && placeChanged) return "A data e o local foram alterados.";
  if (dateChanged) return "A data ou hora deste evento foi alterada.";
  return "O local deste evento foi alterado.";
}

function isQuietHour(date) {
  const hour = Number(localParts(date).hour);
  return hour >= QUIET_HOURS_START || hour < QUIET_HOURS_END;
}

function nextAllowedTime(date) {
  const candidate = new Date(date);
  candidate.setSeconds(0, 0);
  while (isQuietHour(candidate)) {
    candidate.setMinutes(candidate.getMinutes() + 15);
  }
  return candidate;
}

function localDayKey(date) {
  const parts = localParts(date);
  return `${parts.year}-${parts.month}-${parts.day}`;
}

function localParts(date) {
  const values = {};
  new Intl.DateTimeFormat("en-GB", {
    timeZone: TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date).forEach((part) => {
    if (part.type !== "literal") values[part.type] = part.value;
  });
  return values;
}

function weekOfYear(date) {
  const firstDay = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  return Math.ceil((((date - firstDay) / 86400000) + firstDay.getUTCDay() + 1) / 7);
}

function stringData(data) {
  return Object.fromEntries(
      Object.entries(data || {}).map(([key, value]) => [key, String(value)]),
  );
}
