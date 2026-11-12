import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/people/friend_avatar.dart';

void main() {
  test('photoSizedAt decodes at the display size', () {
    final photo = FriendAvatar.photoSizedAt('/tmp/a.jpg',
        diameter: 44, devicePixelRatio: 2.75);
    expect(photo, isA<ResizeImage>());
    final resized = photo! as ResizeImage;
    expect(resized.width, 121);
    expect(resized.height, isNull);
    expect(resized.policy, ResizeImagePolicy.fit);
    expect(resized.imageProvider, isA<FileImage>());
  });

  test('photoSizedAt and photoAt return null without a photo', () {
    expect(FriendAvatar.photoSizedAt(null, diameter: 44, devicePixelRatio: 3),
        isNull);
    expect(FriendAvatar.photoSizedAt('', diameter: 44, devicePixelRatio: 3),
        isNull);
    expect(FriendAvatar.photoAt('/tmp/a.jpg'), isA<FileImage>());
  });

  testWidgets('avatar uses the resized photo for its radius', (tester) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final friend = Friend(
      id: 'a',
      name: 'Anna Lopez',
      birthDate: DateTime(1990),
      avatarPath: '/nonexistent/a.jpg',
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: FriendAvatar(friend: friend, radius: 20)),
    ));
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect((avatar.foregroundImage! as ResizeImage).width, 120);
    expect(find.text('AL'), findsOneWidget); // fallback stays visible
  });
}
