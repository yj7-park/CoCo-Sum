import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/datasources/air_quality_datasource.dart';
import '../../data/datasources/airkorea_web_datasource.dart';
import '../../data/repositories/air_quality_repository_impl.dart';
import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_quality_repository.dart';
import '../../domain/usecases/get_current_air_quality.dart';

// ── DI 트리 ────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  return dio;
});

/// 데이터 소스.
/// 공식 API로 교체 시 여기서 AirKoreaApiDataSource(...)로 바꾸기만 하면 됩니다.
final dataSourceProvider = Provider<AirQualityDataSource>((ref) {
  return AirKoreaWebDataSource(ref.watch(dioProvider));
});

final repositoryProvider = Provider<AirQualityRepository>((ref) {
  return AirQualityRepositoryImpl(ref.watch(dataSourceProvider));
});

final usecaseProvider = Provider<GetCurrentAirQuality>((ref) {
  return GetCurrentAirQuality(ref.watch(repositoryProvider));
});

// ── 위치 ──────────────────────────────────────────────────────

final locationProvider = FutureProvider<Position>((ref) async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    // 권한 거부 시 서울 시청 좌표 사용
    return Future.value(_seoulCityHall);
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.reduced,
      timeLimit: Duration(seconds: 8),
    ),
  );
});

const _seoulCityHall = _FallbackPosition(37.5665, 126.9780);

// ── 공기질 ────────────────────────────────────────────────────

final airQualityProvider = FutureProvider.autoDispose<AirQuality>((ref) async {
  final position = await ref.watch(locationProvider.future);
  final usecase = ref.watch(usecaseProvider);
  return usecase(
    latitude: position.latitude,
    longitude: position.longitude,
  );
});

// ── 내부 헬퍼 ─────────────────────────────────────────────────

/// Geolocator Position 인터페이스를 구현하는 fallback (권한 거부 시).
class _FallbackPosition implements Position {
  const _FallbackPosition(this.latitude, this.longitude);

  @override
  final double latitude;
  @override
  final double longitude;

  @override
  double get accuracy => 0;
  @override
  double get altitude => 0;
  @override
  double get altitudeAccuracy => 0;
  @override
  double get heading => 0;
  @override
  double get headingAccuracy => 0;
  @override
  double get speed => 0;
  @override
  double get speedAccuracy => 0;
  @override
  DateTime get timestamp => DateTime.now();
  @override
  bool get isMocked => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
