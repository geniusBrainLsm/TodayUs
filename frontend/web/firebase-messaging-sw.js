// Firebase Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Firebase 설정
const firebaseConfig = {
  apiKey: "AIzaSyAg_QGjsFWbFQSLTQo1YMDDENdBxjbGNSo",
  authDomain: "todayus-c00d2.firebaseapp.com",
  projectId: "todayus-c00d2",
  storageBucket: "todayus-c00d2.firebasestorage.app",
  messagingSenderId: "873410590555",
  appId: "1:873410590555:web:be4ab45429e16b9e8ecc7e"
};

// Firebase 초기화
firebase.initializeApp(firebaseConfig);

// Firebase Messaging 인스턴스 가져오기
const messaging = firebase.messaging();

// 백그라운드 메시지 처리
messaging.onBackgroundMessage((payload) => {
  console.log('📨 Background message received: ', payload);
  
  const notificationTitle = payload.notification?.title || 'TodayUs';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.type || 'general',
    data: payload.data,
    actions: [
      {
        action: 'open',
        title: '열기'
      },
      {
        action: 'close',
        title: '닫기'
      }
    ],
    requireInteraction: true
  };

  // 백그라운드에서 알림 표시
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// 알림 클릭 처리
self.addEventListener('notificationclick', (event) => {
  console.log('👆 Notification clicked: ', event);
  
  event.notification.close();
  
  if (event.action === 'close') {
    return;
  }
  
  // 앱 열기 또는 포커스
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((clientList) => {
      // 이미 열린 창이 있으면 포커스
      for (const client of clientList) {
        if (client.url.includes('/') && 'focus' in client) {
          return client.focus();
        }
      }
      
      // 새 창 열기
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

console.log('🔔 Firebase Messaging Service Worker registered successfully!');