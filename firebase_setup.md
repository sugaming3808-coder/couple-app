# Firebase 설정 가이드

## 1. Firebase 프로젝트 생성
1. https://console.firebase.google.com 접속
2. "새 프로젝트 추가" 클릭
3. 프로젝트 이름 입력 (예: couple-calendar)

## 2. iOS 앱 등록
1. 프로젝트 설정 > iOS 앱 추가
2. Bundle ID: `com.yourcompany.coupleapp` (Xcode에서 설정한 값과 일치해야 함)
3. 앱 등록 후 `GoogleService-Info.plist` 다운로드
4. `ios/Runner/` 폴더에 파일 복사

## 3. Firebase 서비스 활성화

### Authentication
- Firebase Console > Authentication > 시작하기
- "이메일/비밀번호" 제공업체 활성화

### Cloud Firestore
- Firebase Console > Firestore Database > 데이터베이스 만들기
- 프로덕션 모드로 시작 (또는 테스트 모드)

## 4. Firestore 보안 규칙

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users: 본인만 읽기/쓰기
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Couples: 멤버만 읽기/쓰기
    match /couples/{coupleId} {
      allow read: if request.auth != null &&
        (resource.data.members.hasAny([request.auth.uid]) ||
         resource.data.members.size() < 2);
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        resource.data.members.hasAny([request.auth.uid]);
    }

    // Events: 커플 멤버만 접근
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
        request.resource.data.ownerUid == request.auth.uid;
      allow update, delete: if request.auth != null &&
        resource.data.ownerUid == request.auth.uid;
    }
  }
}
```

## 5. FlutterFire CLI 설정 (권장)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id>
```

이 명령어를 실행하면 `lib/firebase_options.dart` 파일이 자동 생성됩니다.

## 6. main.dart 수정 (firebase_options.dart 생성 후)

```dart
// main.dart의 Firebase.initializeApp() 호출 수정
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## 7. Xcode 설정

1. `ios/Runner.xcworkspace` 열기
2. Runner > General > Bundle Identifier 설정
3. Runner > Signing & Capabilities > Team 설정
4. `GoogleService-Info.plist`가 Runner 그룹에 포함되었는지 확인
