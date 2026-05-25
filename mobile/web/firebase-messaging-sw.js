/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDUqoE_lwDCCz8A-5twZ-PxEdo9qEEehqA',
  appId: '1:250135126119:web:eae0ff70504c5cc59af4c2',
  messagingSenderId: '250135126119',
  projectId: 'nexq-fcebc',
  authDomain: 'nexq-fcebc.firebaseapp.com',
  storageBucket: 'nexq-fcebc.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'NexQ';
  const options = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
