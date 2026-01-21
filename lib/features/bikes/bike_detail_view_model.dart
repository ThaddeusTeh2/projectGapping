import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time.dart';
import '../../di/providers.dart';
import '../../domain/models/bike.dart';
import '../../domain/models/bike_comment.dart';

class BikeDetailState {
  const BikeDetailState({required this.bike, required this.mutation});

  final AsyncValue<Bike?> bike;
  final AsyncValue<void> mutation;

  BikeDetailState copyWith({AsyncValue<Bike?>? bike, AsyncValue<void>? mutation}) {
    return BikeDetailState(
      bike: bike ?? this.bike,
      mutation: mutation ?? this.mutation,
    );
  }
}

final bikeCommentsProvider = StreamProvider.autoDispose.family<List<BikeComment>, String>(
  (ref, bikeId) {
    return ref.watch(commentRepositoryProvider).watchCommentsForBike(bikeId);
  },
);

final bikeDetailViewModelProvider = NotifierProvider.autoDispose.family<
    BikeDetailViewModel,
    BikeDetailState,
    String>(BikeDetailViewModel.new);

class BikeDetailViewModel extends AutoDisposeFamilyNotifier<BikeDetailState, String> {
  @override
  BikeDetailState build(String bikeId) {
    state = const BikeDetailState(
      bike: AsyncLoading(),
      mutation: AsyncData<void>(null),
    );

    Future.microtask(_fetchBike);
    return state;
  }

  Future<void> _fetchBike() async {
    final repo = ref.read(bikeRepositoryProvider);

    final result = await AsyncValue.guard(() => repo.getBikeById(arg));
    state = state.copyWith(bike: result);
  }

  Future<void> retry() => _fetchBike();

  String _requireUid() {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw StateError('You must be signed in.');
    }
    return user.uid;
  }

  Future<void> addComment({required String title, required String body}) async {
    state = state.copyWith(mutation: const AsyncLoading());

    final result = await AsyncValue.guard(() async {
      final uid = _requireUid();
      final repo = ref.read(commentRepositoryProvider);
      await repo.addComment(
        bikeId: arg,
        userId: uid,
        commentTitle: title.trim(),
        comment: body.trim(),
        dateCreatedMillis: nowMillis(),
      );
    });

    state = state.copyWith(mutation: result);
  }

  Future<void> upvoteComment(String commentId) async {
    state = state.copyWith(mutation: const AsyncLoading());

    final result = await AsyncValue.guard(() async {
      _requireUid();
      await ref.read(commentRepositoryProvider).upvoteComment(commentId);
    });

    state = state.copyWith(mutation: result);
  }

  Future<void> downvoteComment(String commentId) async {
    state = state.copyWith(mutation: const AsyncLoading());

    final result = await AsyncValue.guard(() async {
      _requireUid();
      await ref.read(commentRepositoryProvider).downvoteComment(commentId);
    });

    state = state.copyWith(mutation: result);
  }
}
