import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class BaseRepository {
  BaseRepository._();

  static final _instance = BaseRepository._();

  static BaseRepository get instance => _instance;

  static const baseUrl = 'https://maps.phoenix.gov';

  initialize() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl, headers: {
      "Content-Type": "application/json",
    }));
    _dio.interceptors.add(
      PrettyDioLogger(requestHeader: true, responseBody: false),
    );
  }

  Dio get dio => _dio;
  late final Dio _dio;
}
