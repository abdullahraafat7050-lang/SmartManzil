importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDolGCwYtvlqhMDNGkvvi-MdhZvpG-YcFk",
  authDomain: "akilli-manzil.firebaseapp.com",
  projectId: "akilli-manzil",
  storageBucket: "akilli-manzil.firebasestorage.app",
  messagingSenderId: "361380915263",
  appId: "1:361380915263:web:12a35ce285e085ff85b08a"
});

const messaging = firebase.messaging();

// Handle background push notifications
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'SmartManzil';
  const body  = payload.notification?.body  ?? '';
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  });
});
