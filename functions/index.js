const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Firestore trigger: run if there's a new notification in the collection
exports.sendNotification = functions.firestore
    .document("notifications_dump/{notificationId}")
    .onCreate(async (snap, context) => {
        const data = snap.data()

        const title = data.title || "New Notification"
        const body = data.body || ""
        const fcmToken = data.fcmToken

        if(!fcmToken) {
            console.log("Tidak ada Token di dokumen notifikasi, skip")
            return null
        }

        const message = {
            notification: {
                title: title,
                body: body,
            },
            token: fcmToken,
        }

        try {
            const response = await admin.messaging().send(message)
            console.log("Notifikasi berhasil dikirim:", response)
        } catch (e) {
            console.error("Gagal mengirim notifikasi:", e)
            return null
        }
    })