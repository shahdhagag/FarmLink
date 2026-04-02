import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:farmlink/data/models/weather_model.dart';

import '../../data/services/LocationService.dart';
import '../../data/services/auth_services.dart';
import '../../data/services/firestore_Services.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/user.dart';

// ─── Services ─────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((_) => AuthService());
final firestoreServiceProvider =
Provider<FirestoreService>((_) => FirestoreService());
final locationServiceProvider =
Provider<LocationService>((_) => LocationService());

// ─── Auth State ───────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).watchCurrentUserStream(authState.uid);
});

// ─── Crops ────────────────────────────────────────────────────────────────────
// Crops
final cropFilterProvider = StateProvider<String>((_) => 'All');
final cropSearchProvider = StateProvider<String>((_) => '');

final allCropsProvider = StreamProvider.family<List<Crop>, String>((ref, filter) {
  return ref.watch(firestoreServiceProvider).watchAllCrops(filterType: filter);
});

final filteredCropsProvider = Provider<AsyncValue<List<Crop>>>((ref) {
  // Watch the search text and the selected category chip
  final search = ref.watch(cropSearchProvider).toLowerCase();
  final filter = ref.watch(cropFilterProvider);

  // Watch all crops from the database
  final allCropsAsync = ref.watch(allCropsProvider('All'));

  return allCropsAsync.whenData((list) {
    return list.where((crop) {
      // 1. Logic for Search (matches product name or farmer name)
      final matchesSearch = crop.product.toLowerCase().contains(search) ||
          crop.farmerName.toLowerCase().contains(search);

      // 2. Logic for Categories
      bool matchesCategory = true;
      if (filter == 'Organic') {
        matchesCategory = crop.isOrganic;
      } else if (filter == 'Hybrid') {
        matchesCategory = !crop.isOrganic;
      } else if (filter == 'Vegetables') {
        // This checks the category field in your Crop model
        matchesCategory = crop.category.toLowerCase() == 'vegetable' ||
            crop.category.toLowerCase() == 'vegetables';
      } else if (filter == 'Fruits') {
        matchesCategory = crop.category.toLowerCase() == 'fruit' ||
            crop.category.toLowerCase() == 'fruits';
      }

      return matchesSearch && matchesCategory;
    }).toList();
  });
});

final farmerCropsProvider = StreamProvider.family<List<Crop>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).watchFarmerCrops(uid);
});
// final cropFilterProvider = StateProvider<String>((_) => 'All');
// final cropSearchProvider = StateProvider<String>((_) => '');
//
// final allCropsProvider = StreamProvider.family<List<Crop>, String>((ref, filter) {
//   return ref.watch(firestoreServiceProvider).watchAllCrops(filterType: filter);
// });
//
// final filteredCropsProvider = Provider<AsyncValue<List<Crop>>>((ref) {
//   final filter = ref.watch(cropFilterProvider);
//   final search = ref.watch(cropSearchProvider).toLowerCase();
//   final cropsAsync = ref.watch(allCropsProvider(filter));
//
//   return cropsAsync.whenData((crops) {
//     if (search.isEmpty) return crops;
//     return crops
//         .where((c) =>
//     c.product.toLowerCase().contains(search) ||
//         c.farmerName.toLowerCase().contains(search) ||
//         c.location.toLowerCase().contains(search) ||
//         c.description.toLowerCase().contains(search))
//         .toList();
//   });
// });
//
// final farmerCropsProvider =
// StreamProvider.family<List<Crop>, String>((ref, uid) {
//   return ref.watch(firestoreServiceProvider).watchFarmerCrops(uid);
// });

// ─── Orders ───────────────────────────────────────────────────────────────────

final buyerOrdersProvider =
StreamProvider.family<List<Order>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).watchBuyerOrders(uid).map(
        (orders) => orders.map((order) => order as Order).toList(),
  );
});

final farmerOrdersProvider =
StreamProvider.family<List<Order>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).watchFarmerOrders(uid).map(
        (orders) => orders.map((order) => order as Order).toList(),
  );
});

// ─── Chat ─────────────────────────────────────────────────────────────────────

final userChatsProvider =
StreamProvider.family<List<ChatRoom>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).watchUserChats(uid);
});

final chatMessagesProvider =
StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(firestoreServiceProvider).watchMessages(chatId);
});

// ─── Weather ──────────────────────────────────────────────────────────────────


class WeatherState {
  final WeatherModel? data;
  final bool isLoading;
  final String? error;
  final double? lat;
  final double? lon;

  const WeatherState({
    this.data,
    this.isLoading = false,
    this.error,
    this.lat,
    this.lon,
  });

  WeatherState copyWith({
    WeatherModel? data,
    bool? isLoading,
    Object? error = _sentinel,
    double? lat,
    double? lon,
  }) =>
      WeatherState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: error == _sentinel ? this.error : error as String?,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
      );
}

const _sentinel = Object();


class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier(this._locationService) : super(const WeatherState());

  final LocationService _locationService;

  Future<void> fetch() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Get position with a generous timeout
      final position = await _locationService.getCurrentPosition();

      // 2. Double check coordinates
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        throw Exception('Location is not set. Please enable GPS and select a location on your device/emulator.');
      }

      // 3. Fetch weather from service
      final weather = await _locationService.getWeather(
          position.latitude,
          position.longitude
      );

      // 4. Update state with data
      state = WeatherState(
        data: weather,
        isLoading: false,
        lat: position.latitude,
        lon: position.longitude,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }}

final weatherProvider =
StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier(ref.watch(locationServiceProvider));
});
// ─── Profile editing ──────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileNotifier(this._firestoreService, this._locationService)
      : super(const AsyncData(null));

  final FirestoreService _firestoreService;
  final LocationService _locationService;

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await _firestoreService.updateUser(uid, data);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}

final profileNotifierProvider =
StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  return ProfileNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(locationServiceProvider),
  );
});